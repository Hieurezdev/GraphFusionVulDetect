import React from "react";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";

interface TruncatedTextProps {
  text: string;
  className?: string;
  maxLines?: number;
  showTooltip?: boolean;
}

export const TruncatedText: React.FC<TruncatedTextProps> = ({ 
  text, 
  className = "", 
  maxLines = 1,
  showTooltip = true 
}) => {
  // `truncate` only cuts a block box, and a flex child needs min-w-0 to shrink; a bare span let long names spill out.
  const truncateClass = maxLines === 1 ? "block min-w-0 truncate" : `line-clamp-${maxLines}`;
  
  if (!showTooltip) {
    return (
      <span className={`${truncateClass} break-words ${className}`}>
        {text}
      </span>
    );
  }

  return (
    <TooltipProvider>
      <Tooltip>
        <TooltipTrigger asChild>
          <span className={`${truncateClass} break-words cursor-help ${className}`}>
            {text}
          </span>
        </TooltipTrigger>
        <TooltipContent side="top" className="max-w-xs break-words">
          <p>{text}</p>
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
};

export default TruncatedText;
