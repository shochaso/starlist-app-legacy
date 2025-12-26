"use client";

import React from "react";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {}

export function Button({ children, className = "", ...rest }: ButtonProps) {
  return (
    <button className={className} {...rest}>
      {children}
    </button>
  );
}







