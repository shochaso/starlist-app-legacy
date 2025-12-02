/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        starData: {
          background: "#F6F7F9",
          surface: "#FFFFFF",
          border: "#E2E2E2",
          textMuted: "#8E8E93",
          youtubeAccent: "#F3A7A8",
          videoAccent: "#C8E7FF",
          shoppingAccent: "#F7D46C",
          musicAccent: "#A5C8FF",
          receiptAccent: "#D7D7E4",
          badgeBg: "#F2F2F5",
        },
      },
      boxShadow: {
        starData: "0 12px 30px rgba(15, 23, 42, 0.08)",
      },
    },
  },
  plugins: [],
};
