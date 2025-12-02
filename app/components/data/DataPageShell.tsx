"use client";

import React from "react";

interface DataPageShellProps {
  children: React.ReactNode;
}

export function DataPageShell({ children }: DataPageShellProps) {
  return (
    <div className="min-h-screen bg-starData-background">
      <div className="mx-auto w-full max-w-5xl px-10 pt-14 pb-20 space-y-12">
        {children}
      </div>
    </div>
  );
}
