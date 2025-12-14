const config = {
  typescript: {
    tsconfigPath: "./next-tsconfig.json",
  },
  async redirects() {
    return [
      {
        source: "/",
        destination: "/teaser",
        permanent: false,
      },
    ];
  },
};

export default config;
