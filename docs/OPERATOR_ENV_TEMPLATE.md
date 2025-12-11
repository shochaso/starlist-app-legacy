# STARLIST 運営情報用 env テンプレート

以下の値は **本番で公開してよい情報** を、あなたのローカル環境でだけ `.env.local` に記入してください。
このファイル自体には実際の氏名・住所・メールアドレスを書かないでください。

```env
# 運営者名（屋号 + 代表者名など）。例: STARLIST / 山田太郎
NEXT_PUBLIC_OPERATOR_NAME=

# 住所（開業届と一致させる）。例: 東京都〇〇区〇〇 1-2-3 〇〇ビル 101
NEXT_PUBLIC_OPERATOR_ADDRESS=

# 公開用の連絡先メールアドレス。例: contact@example.com
NEXT_PUBLIC_OPERATOR_EMAIL=
```

`NEXT_PUBLIC_` プレフィックスがついているため、フロントエンド（ティザーサイト）から参照されます。
