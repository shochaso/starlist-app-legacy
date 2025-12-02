# StarData Repository Notes

- StarDataItem represents a single record surfaced on the data page, with metadata such as starId, category, genre, source, and timestamps.
- StarDataRepository abstracts the source; WS10A provides a mock implementation and WS11 adds Supabase integration.
- MockStarDataRepository (WS12) now supports only Hanayama Mizuki and Kato Junichi, with fallback to Hanayama Mizuki for unknown stars.
- SupabaseStarDataRepository (WS11) implements actual Supabase queries against `star_data_items` table.

## Repository Provider Configuration (WS11)

- `starDataRepositoryProvider` can switch between Mock and Supabase via `USE_SUPABASE_STAR_DATA` flag:
  - Default: Mock (for development)
  - To use Supabase: Set `--dart-define=USE_SUPABASE_STAR_DATA=true` at build time
  - Falls back to Mock if Supabase client is unavailable
- `starDataProvider` (WS18) observes the same flag to decide between Supabase and Mock when `/my/data` or `/stars/:username/data` render.
- `starDataItemsProvider` uses the repository from `starDataRepositoryProvider`
- `starDataPacksProvider` aggregates the `starDataItemsProvider` output into `StarDataPack` instances for UI rendering (WS20).
- RPC parameters for items/pack/summary now originate from `lib/src/features/star_data/utils/star_data_rpc_params.dart`, guaranteeing consistent keys and date formatting across Supabase calls.

## Supabase Production Mode (WS18)

- Enable real data by passing `--dart-define=USE_SUPABASE_STAR_DATA=true` (and the local `SUPABASE_URL`/`SUPABASE_ANON_KEY`) when running Flutter. This flag is read through `bool.fromEnvironment` in `star_data_providers.dart`.
- Supabase data flow:
  1. `SupabaseStarDataRepository.fetchStarData` queries `star_data_items` ordered by `occurred_at DESC`.
  2. `StarDataViewPageSimple` uses `starDataItemsProvider`, which in turn reads from `starDataRepositoryProvider`.
  3. DataImport + `StarDataSaver` persist new records into the same table (`category`, `source`, `raw_payload`, `occurred_at`, etc.).
- The local setup steps below (see [Supabase Local Docker Setup](SUPABASE_LOCAL_DOCKER_SETUP.md)) describe how to migrate/seed `star_data_items` and run Flutter with the Supabase flag so that `/my/data` shows real Supabase rows.

## Supabase Integration (WS11)

### Database Schema

- Table: `public.star_data_items`
- Migration: `supabase/migrations/20250128000000_star_data_items.sql`
- Columns:
  - `id` (UUID, primary key)
  - `star_id` (TEXT) - Star identifier (e.g., "star_hanayama_mizuki")
  - `category` (TEXT) - "youtube", "shopping", "music", etc.
  - `genre` (TEXT) - Sub-category like "video_variety", "shopping_work"
  - `title` (TEXT) - Main title
  - `subtitle` (TEXT) - Optional subtitle
  - `source` (TEXT) - Service name (e.g., "YouTube", "Amazon")
  - `occurred_at` (DATE) - When the activity occurred
  - `created_at` (TIMESTAMPTZ) - Record creation time
  - `raw_payload` (JSONB) - Original data from intake process

### Seed Data

- **Hanayama Mizuki**: `supabase/seed/star_data_items_hanayama_mizuki.sql`
  - 12 sample records:
    - 6 YouTube entries (video_variety, video_bgm, video_asmr)
    - 3 Shopping entries (shopping_work)
    - 3 Music entries (music_work)
- **Kato Junichi**: `supabase/seed/star_data_items_kato_junichi.sql` (WS12)
  - 10 sample records:
    - 4 YouTube entries (game streams, chat streams)
    - 3 Shopping entries (gaming peripherals, daily items)
    - 3 Music entries (BGM playlists for streaming)
- Usage: Run after migration:
  ```bash
  psql -d your_database -f supabase/seed/star_data_items_hanayama_mizuki.sql
  psql -d your_database -f supabase/seed/star_data_items_kato_junichi.sql
  ```

### Data Flow

1. **Intake Process** → Saves data to `star_data_items` table (via Supabase Functions or direct insert)
2. **SupabaseStarDataRepository** → Queries `star_data_items` by `star_id`, ordered by `occurred_at DESC`
3. **StarDataPack Aggregator** → Groups daily items, derives `mainCategory`/`mainSummaryText`/`secondarySummaryText`, and preserves original `StarDataItem` list.
4. **StarDataViewPageSimple** → Consumes `starDataPacksProvider` to render per-day cards.
5. 検索バーとカテゴリタブは WS20B で “白い pill 形入力＋枠線の軽い tab” にリファイン済。検索欄には「キーワードで検索（タイトル・キーワードなど）」がプレースホルダー、カテゴリは「すべて」「動画（YouTube）」「ショッピング」「音楽」「レシート」の 5 軸。
6. **StarDataTimeline (WS22)** → `StarDataPack` をさらに today/past で分割し、`findTodayStarDataPack`/`findPastStarDataPacks` を使って「TODAY DATA PACK」と「過去の DATA PACK」を縦のタイムラインで並べる。検索語とカテゴリフィルタは両セクションに適用され、過去パックは最大 30 日分で表示される。CTA 挙動（YouTube=無料 Snackbar、それ以外は Paywall）は Today/Pastとも共通。
7. **StarDataDailyDetailPage (WS23)** → YouTube系のパック CTA は `/stars/:username/data/day?date=yyyy-MM-dd&category=...` または `/my/data/day?...` に遷移し、`starDataItemsByDayProvider`（starId／日付／カテゴリ）で明細を取得。詳細画面は AppBar＋summary＋StarDataItem ListView を表示し、非YouTubeは PaywallPlansDialogをそのまま使う。
8. **StarData soft delete (WS24A)** → `star_data_items` に `is_hidden:boolean DEFAULT false`/`hidden_at:timestamptz` を追加し、`StarDataRepository.hideStarDataItem` で soft delete を実行。Supabase/mock Repository は `is_hidden=false` のみを返し、hidden データは timeline/pack/detail から排除。UI の「非表示」ボタンは WS24B 以降で追加予定。

### RLS Policies

- Stars can read/insert their own data (based on `star_id` matching profile)
- Public read access is enabled (TODO: restrict to followers/subscribers based on business logic)

## Production Star Configuration (WS12)

### Supported Stars

- **Hanayama Mizuki** (`star_hanayama_mizuki`)
  - Username: `hanayama-mizuki`, `花山瑞樹`
  - Default fallback star for unknown usernames
- **Kato Junichi** (`star_kato_junichi`)
  - Username: `kato-junichi`, `加藤純一`

### StarIdResolver Fallback Strategy

- `usernameToStarId()` maps known stars to their starId
- Unknown usernames fall back to `star_hanayama_mizuki`
- `currentUserStarId()` returns `star_hanayama_mizuki` if user is not logged in, not a star, or username is missing
- TODO: In production, replace with actual database lookup from `profiles` table

### Routes

- `/stars/hanayama-mizuki/data` → Hanayama Mizuki's Supabase data
- `/stars/kato-junichi/data` → Kato Junichi's Supabase data
- `/stars/:unknown/data` → Falls back to Hanayama Mizuki's data
- `/my/data` → Current user's data (falls back to Hanayama Mizuki if not a star or username missing)

### Mock Repository Behavior (WS12)

- Removed generic/other-star mock data
- Supports only `star_hanayama_mizuki` and `star_kato_junichi`
- Unknown starIds fall back to Hanayama Mizuki data
- Mock is for local development only; Supabase seed data is primary

## UI Features (WS10C)

### StarDataViewPageSimple UI Components

- **Category/Genre Filter Chips**: Horizontal scrollable filter chips for category and genre selection
  - Category chips appear at the top when data is loaded
  - Genre chips appear below category chips when a category is selected
  - "すべて" (All) option available for both filters
  - Filter state managed via `selectedCategoryProvider` and `selectedGenreProvider`

- **Data Cards**: Each card displays:
  - Category pill (top-left)
  - Title (bold)
  - Subtitle (if available)
  - Source icon and name, date (bottom row)
  - "このデータの詳細を見る" button (full-width at bottom)

- **Paywall Dialog**: `PaywallPlansDialog` shows 3 subscription plans:
  - ライトプラン (¥480/month)
  - スタンダードプラン (¥980/month) - recommended
  - プレミアムプラン (¥1,980/month)
  - Each plan shows features and "このプランを選ぶ" button (TODO: integrate with subscription flow)

### View Detail Button Behavior

- **YouTube category**: Shows snackbar "このデータは無料で閲覧できます" (no paywall)
- **Other categories** (shopping, music, etc.): Shows `PaywallPlansDialog`
- Category check uses `_isFreeCategory()` helper (case-insensitive)

### Testing

- Widget tests in `test/star_data/star_data_view_page_simple_paywall_test.dart`
- Tests verify:
  - YouTube category shows snackbar (not paywall)
- Non-YouTube categories show paywall dialog with plan names

## DataImport → star_data_items Integration (WS13)

- `/data-import` now routes through `DataImportScreen` into YouTube/Receipt import flows, and each confirmed import writes a `StarDataItem` via `StarDataSaver`.
- **YouTube flow**: `YouTubeImportWorkflow.saveSelected` calls `StarDataSaver.save` with `category: 'youtube'`, `genre: 'video_watch'`, `source: 'YouTube'`, `subtitle` set to the channel name, and `raw_payload` carrying the enriched metadata (video URL, thumbnail, match score, OCR confidence, view timestamp). Errors during this extra persistence are logged but do not block the existing UI snackbar.
- **Receipt flow**: `ReceiptImportScreen` saves selected items with `category: 'shopping'`, `genre` equal to the parser's inferred category label, `source: 'Receipt OCR'`, and `raw_payload` containing price, quantity, store name, and the OCR-ed text. Each confirmation also sets `processedReceipt` so the UI can show totals while triggering the `star_data_items` insert.
- `StarDataSaver` resolves `star_id` through `StarIdResolver.currentUserStarId`; if the user is not authenticated/a star or lacks a username, the helper falls back to `star_hanayama_mizuki`. This helper is re-used by YouTube and receipt flows so future data-intake work can share the same mapping.
- ImportDiagnose (`api/ocr`, `api/enrich`) and the Supabase `intake` edge function are annotated with TODOs to persist into `star_data_items` in a later WS14 phase once the intake pipeline is fully consolidated.

## StarData Service Master (WS-SERVICE-FILTER-01)

### Category x Service Mapping
Defines available service options for each StarDataCategory.
See `lib/src/features/star_data/utils/star_data_service_master.dart`.

| Category | Service ID | Label | Note |
|---|---|---|---|
| youtube | youtube | YouTube | |
| youtube | prime_video | Prime Video | |
| youtube | abema | ABEMA | |
| youtube | netflix | Netflix | |
| youtube | tver | TVer | |
| shopping | amazon | Amazon | |
| shopping | rakuten | 楽天市場 | |
| shopping | yahoo_shopping | Yahoo!ショッピング | |
| shopping | convenience_store | コンビニ | |
| shopping | mercari | メルカリ | |
| music | youtube_music | YouTube Music | |
| music | spotify | Spotify | |
| music | apple_music | Apple Music | |
| music | amazon_music | Amazon Music | |
| music | line_music | LINE MUSIC | |
| receipt | receipt_convenience | コンビニ | |
| receipt | receipt_supermarket | スーパー | |
| receipt | receipt_drugstore | ドラッグストア | |
| receipt | receipt_restaurant | 外食チェーン | |
| receipt | receipt_online | ネット通販 | |

### Filter Behavior
- **Upper Tab**: Category (e.g. YouTube, Shopping)
- **Lower Tab**: Service (e.g. Amazon, Rakuten) - Horizontal scroll
- **Genre**: Temporarily hidden/deprecated in UI, replaced by Service filter.
- Selecting a service filters `StarDataPack` list to show packs containing at least one item with `source == service_id`.
- "All" (`all`) service option shows all packs in the category.
