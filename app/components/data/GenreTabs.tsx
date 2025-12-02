"use client";

import React from "react";

type GenreOption = {
  label: string;
  value: string;
};

interface GenreTabsProps {
  options: GenreOption[];
  value: string;
  onChange: (value: string) => void;
}

export function GenreTabs({ options, value, onChange }: GenreTabsProps) {
  if (!options.length) {
    return null;
  }

  return (
    <div className="overflow-x-auto">
      <div className="flex gap-2 whitespace-nowrap pb-1">
        {options.map((option) => {
          const isActive = option.value === value;
          return (
            <button
              key={option.value}
              type="button"
              onClick={() => onChange(option.value)}
              className={`rounded-full border px-4 py-1.5 text-xs font-medium transition-colors ${
                isActive
                  ? "border-starData-border bg-white text-slate-900"
                  : "border-starData-border bg-transparent text-slate-600 hover:bg-white"
              }`}
            >
              {option.label}
            </button>
          );
        })}
      </div>
    </div>
  );
}
