"use client";

import React from "react";

type CategoryOption = {
  label: string;
  value: string;
};

interface CategoryTabsProps {
  options: CategoryOption[];
  value: string;
  onChange: (value: string) => void;
}

export function CategoryTabs({ options, value, onChange }: CategoryTabsProps) {
  return (
    <div className="overflow-x-auto">
      <div className="flex gap-3 whitespace-nowrap pb-1">
        {options.map((option) => {
          const isActive = option.value === value;
          return (
            <button
              key={option.value}
              type="button"
              onClick={() => onChange(option.value)}
              className={`rounded-full border px-5 py-2 text-sm font-medium transition-colors ${
                isActive
                  ? "border-starData-border bg-white text-slate-900 shadow-sm"
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
