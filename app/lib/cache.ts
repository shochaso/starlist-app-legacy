import { createClient } from '@supabase/supabase-js';

interface CacheEntry<T> {
  data: T;
  expires: number;
}

class CacheStore {
  private store = new Map<string, CacheEntry<unknown>>();
  private readonly supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  private readonly supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  private supabase = this.supabaseUrl && this.supabaseKey
    ? createClient(this.supabaseUrl, this.supabaseKey)
    : null;

  private isDevelopment(): boolean {
    return process.env.NODE_ENV === 'development';
  }

  private async getSupabaseCache<T>(key: string): Promise<T | null> {
    if (!this.supabase) return null;

    try {
      const { data, error } = await this.supabase
        .from('cache')
        .select('data, expires')
        .eq('key', key)
        .single();

      if (error || !data) return null;

      const entry = data as CacheEntry<T>;
      if (Date.now() > entry.expires) {
        await this.supabase.from('cache').delete().eq('key', key);
        return null;
      }

      return entry.data;
    } catch {
      return null;
    }
  }

  private async setSupabaseCache<T>(key: string, data: T, ttlMs: number): Promise<void> {
    if (!this.supabase) return;

    try {
      const entry: CacheEntry<T> = {
        data,
        expires: Date.now() + ttlMs,
      };

      await this.supabase
        .from('cache')
        .upsert({ key, data: entry, expires: entry.expires });
    } catch {
      // Silently fail for production cache issues
    }
  }

  async get<T>(key: string): Promise<T | null> {
    // Priority 1: globalThis for development
    if (this.isDevelopment() && typeof globalThis !== 'undefined') {
      const entry = (globalThis as any).__CACHE__?.[key] as CacheEntry<T> | undefined;
      if (entry && Date.now() <= entry.expires) {
        return entry.data;
      }
    }

    // Priority 2: Supabase KV for production
    return await this.getSupabaseCache<T>(key);
  }

  async set<T>(key: string, data: T, ttlMs: number): Promise<void> {
    const entry: CacheEntry<T> = {
      data,
      expires: Date.now() + ttlMs,
    };

    // Priority 1: globalThis for development
    if (this.isDevelopment() && typeof globalThis !== 'undefined') {
      if (!(globalThis as any).__CACHE__) {
        (globalThis as any).__CACHE__ = {};
      }
      (globalThis as any).__CACHE__[key] = entry;
    }

    // Priority 2: Supabase KV for production
    await this.setSupabaseCache(key, data, ttlMs);
  }

  async invalidate(key: string): Promise<void> {
    // Clear development cache
    if (this.isDevelopment() && typeof globalThis !== 'undefined') {
      delete (globalThis as any).__CACHE__?.[key];
    }

    // Clear production cache
    if (this.supabase) {
      try {
        await this.supabase.from('cache').delete().eq('key', key);
      } catch {
        // Silently fail
      }
    }
  }
}

/**
 * Generic caching layer for STARLIST Intake Pipeline.
 *
 * Caches are prioritized as follows:
 * 1. globalThis (development) - fastest, survives hot reloads
 * 2. Supabase KV (production) - persistent, shared across instances
 *
 * Cache keys:
 * - yt:video:{videoId} - YouTube video metadata (24h TTL)
 * - groq:{sha256(prompt)} - Groq OCR parsing results (6h TTL)
 */
export const cache = new CacheStore();

// Cache TTL constants (in milliseconds)
export const CACHE_TTL = {
  YOUTUBE_VIDEO: 24 * 60 * 60 * 1000, // 24 hours
  GROQ_RESPONSE: 6 * 60 * 60 * 1000,  // 6 hours
} as const;

// Cache key generators
export const cacheKeys = {
  youtubeVideo: (videoId: string) => `yt:video:${videoId}`,
  groqResponse: (hash: string) => `groq:${hash}`,
} as const;
