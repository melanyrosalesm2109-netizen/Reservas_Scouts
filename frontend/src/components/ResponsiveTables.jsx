import { useEffect } from "react";

// Keep the column names next to each value when tables become cards on mobile.
export default function ResponsiveTables({ pathname }) {
  useEffect(() => {
    const root = document.querySelector(".main-content");
    if (!root) return;
    const labelCells = () => {
      root.querySelectorAll("table").forEach(table => {
        const titles = [...table.querySelectorAll("thead th")].map(th => th.textContent.trim());
        if (!titles.length) return;
        table.classList.add("responsive-data-table");
        [...table.tBodies].forEach(body => [...body.rows].forEach(row => {
          [...row.cells].forEach((cell, index) => {
            if (cell.colSpan === 1) cell.dataset.column = titles[index] || "";
          });
        }));
      });
    };
    labelCells();
    const observer = new MutationObserver(labelCells);
    observer.observe(root, { childList: true, subtree: true, characterData: true });
    return () => observer.disconnect();
  }, [pathname]);
  return null;
}
