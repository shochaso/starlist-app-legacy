"use client";

import React from "react";

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {}

export function Card({ children, className = "", ...rest }: CardProps) {
  return (
    <div className={className} {...rest}>
      {children}
    </div>
  );
}

interface CardContentProps
  extends React.HTMLAttributes<HTMLDivElement>,
    React.PropsWithChildren {}

export function CardContent({
  children,
  className = "",
  ...rest
}: CardContentProps) {
  return (
    <div className={className} {...rest}>
      {children}
    </div>
  );
}







