/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  env: {
    NEXT_PUBLIC_CHAIN_ID: process.env.NEXT_PUBLIC_CHAIN_ID || '2021',
    NEXT_PUBLIC_RPC_URL: process.env.NEXT_PUBLIC_RPC_URL || 'https://saigon-testnet.roninchain.com/rpc',
    NEXT_PUBLIC_POINTS_VAULT_ADDRESS: process.env.NEXT_PUBLIC_POINTS_VAULT_ADDRESS || '',
    NEXT_PUBLIC_POINTS_RECEIPT_ADDRESS: process.env.NEXT_PUBLIC_POINTS_RECEIPT_ADDRESS || '',
    NEXT_PUBLIC_POINTS_STREAM_ADDRESS: process.env.NEXT_PUBLIC_POINTS_STREAM_ADDRESS || '',
  },
  webpack: (config) => {
    config.resolve.fallback = { fs: false, net: false, tls: false };
    return config;
  },
};

module.exports = nextConfig;
