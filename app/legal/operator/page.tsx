'use client';

const operatorName = process.env.NEXT_PUBLIC_OPERATOR_NAME;
const operatorAddress = process.env.NEXT_PUBLIC_OPERATOR_ADDRESS;
const operatorEmail = process.env.NEXT_PUBLIC_OPERATOR_EMAIL;

export default function OperatorInfoPage() {
  return (
    <main className="min-h-screen bg-black text-white py-16 px-6">
      <div className="max-w-3xl mx-auto space-y-4 text-sm text-white/80">
        <h1 className="text-2xl font-bold mb-4">運営情報</h1>
        {operatorName && (
          <p>
            <span className="font-semibold">運営者名：</span>
            {operatorName}
          </p>
        )}
        {operatorAddress && (
          <p>
            <span className="font-semibold">所在地：</span>
            {operatorAddress}
          </p>
        )}
        {operatorEmail && (
          <p>
            <span className="font-semibold">お問い合わせ：</span>
            {operatorEmail}
          </p>
        )}
        <p className="text-xs text-white/50 mt-4">
          ※ ここに表示される内容は、.env.local に設定された情報を元にしています。
        </p>
      </div>
    </main>
  );
}
