"use client";

import React from "react";

interface SeparatorProps extends React.HTMLAttributes<HTMLDivElement> {}

export function Separator({ className = "", ...rest }: SeparatorProps) {
  return <div className={className} {...rest} />;
}


