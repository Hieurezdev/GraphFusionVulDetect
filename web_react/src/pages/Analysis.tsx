import { lazy, Suspense, useEffect, useState, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import Header from "@/components/Header";
import { ArrowLeft, XCircle } from "lucide-react";
import { AnalysisReport } from "@/components/AnalysisReport";
import { flaggedFunctions } from "@/lib/findings";
import { RefactorChatbot } from "@/components/RefactorChatbot";
import { projectService, FunctionReview } from "@/services/project";
import { toast } from "sonner";
import { useT } from "@/i18n";
import { useAuth } from "@/contexts/AuthContext";

// Monaco is large: load the IDE only when a finished analysis shows it.
const ContractIDE = lazy(() => import("@/components/ContractIDE"));

interface AnalysisData {
  status: "pending" | "analyzing" | "complete" | "error";
  projectId?: string;
  projectName: string;
  fileName: string;
  sessionId?: string;
  results?: any;
  error?: string;
}

const Analysis = () => {
  const navigate = useNavigate();
  const t = useT();
  const { can, assistant } = useAuth();
  const [analysisData, setAnalysisData] = useState<AnalysisData | null>(null);
  const [streamingResults, setStreamingResults] = useState<any[]>([]);
  const [isStreaming, setIsStreaming] = useState(false);
  const [reviews, setReviews] = useState<FunctionReview[]>([]);

  const handleBack = () => {
    const storedData = sessionStorage.getItem("contractAnalysis");
    if (storedData) {
      const data = JSON.parse(storedData);
      if (data.isExistingProject && data.projectId) {
        navigate(`/project/${data.projectId}`);
        return;
      }
    }
    navigate("/analysis");
  };

  useEffect(() => {
    const storedData = sessionStorage.getItem("contractAnalysis");
    const fileContent = sessionStorage.getItem("contractFile");
    
    if (!storedData || !fileContent) {
      navigate("/analysis");
      return;
    }

    const data = JSON.parse(storedData);
    
    // Check if we have project information from the new flow
    if (!data.projectId) {
      toast.error(t("Project information missing. Please start from the beginning."));
      navigate("/analysis");
      return;
    }

    setAnalysisData({
      status: "analyzing",
      projectId: data.projectId,
      projectName: data.projectName,
      fileName: data.fileName,
      sessionId: data.sessionId,
    });

    // A reload reattaches to the analysis already running (or finished) on the server instead of uploading the file again.
    if (data.sessionId) {
      followAnalysis(data.sessionId);
    } else {
      startAnalysis(fileContent, data.projectId, data.fileName);
    }
  }, [navigate]);

  const rememberSession = (sessionId: string) => {
    const stored = sessionStorage.getItem("contractAnalysis");
    if (!stored || !sessionId) return;
    sessionStorage.setItem("contractAnalysis", JSON.stringify({ ...JSON.parse(stored), sessionId }));
  };

  const startAnalysis = async (fileContent: string, projectId: string, fileName: string) => {
    setIsStreaming(true);
    try {
      // Create a File object from the content
      const blob = new Blob([fileContent], { type: 'text/plain' });
      const file = new File([blob], fileName, { type: 'text/plain' });

      // Use project service to start analysis with project association
      const { sessionId, stream } = await projectService.analyzeWithProject(file, projectId);
      setAnalysisData(prev => prev ? { ...prev, sessionId } : null);
      rememberSession(sessionId);
      await consumeStream(stream);
    } catch (error) {
      failAnalysis(error);
    }
  };

  const followAnalysis = async (sessionId: string) => {
    setIsStreaming(true);
    try {
      await consumeStream(await projectService.followSession(sessionId));
    } catch (error) {
      failAnalysis(error);
    }
  };

  const failAnalysis = (error: unknown) => {
    console.error("Analysis error:", error);
    setIsStreaming(false);
    const errorMessage = error instanceof Error ? error.message : "Analysis failed";
    setAnalysisData(prev => prev ? { ...prev, status: "error", error: errorMessage } : null);
    toast.error(t("Analysis failed: {e}", { e: errorMessage }));
  };

  const consumeStream = async (stream: ReadableStream) => {
    {
      // Process the stream
      const reader = stream.getReader();
      const decoder = new TextDecoder();
      let buffer = "";

      while (true) {
        const { done, value } = await reader.read();
        
        if (done) {
          setIsStreaming(false);
          setAnalysisData(prev => prev ? { ...prev, status: "complete" } : null);
          break;
        }

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split("\n");
        buffer = lines.pop() || "";

        for (const line of lines) {
          if (line.trim()) {
            try {
              const parsed = JSON.parse(line);
              setStreamingResults(prev => [...prev, parsed]);
              
              // An error without a vulnerability type stopped the whole analysis; one scan failing does not.
              if (parsed.node === "error" && !parsed.vulnerability) {
                throw new Error(parsed.output?.error || "Analysis failed");
              }
            } catch (parseError) {
              console.error("Failed to parse line:", line, parseError);
              if (parseError instanceof Error && parseError.message.includes("Analysis failed")) {
                throw parseError;
              }
            }
          }
        }
      }
    }
  };

  if (!analysisData) {
    return null;
  }

  const backLabel = (() => {
    const storedData = sessionStorage.getItem("contractAnalysis");
    if (storedData) {
      const data = JSON.parse(storedData);
      if (data.isExistingProject) return t("Project");
    }
    return t("Upload");
  })();

  const statusChip = {
    pending: { variant: "outline" as const, label: t("Pending") },
    analyzing: { variant: "signal" as const, label: t("Analyzing") },
    complete: { variant: "secondary" as const, label: t("Complete") },
    error: { variant: "destructive" as const, label: t("Error") },
  }[analysisData.status];

  return (
    <div className="min-h-dvh bg-background">
      <Header />

      <main id="main" className="shell py-10 lg:py-12">
        <Button variant="link" onClick={handleBack} className="gap-2 text-sm text-ink-2">
          <ArrowLeft className="h-4 w-4" />
          {t("Back to {where}", { where: backLabel })}
        </Button>

        <div className="mt-6 flex flex-wrap items-end justify-between gap-4 border-b border-rule pb-8">
          <div className="min-w-0">
            <h1 className="break-words text-4xl leading-none">{analysisData.projectName}</h1>
            <p className="code-text mt-3 break-all text-sm text-ink-2">{analysisData.fileName}</p>
          </div>
          <p className="flex items-center gap-3 text-sm text-muted-foreground" role="status">
            {t("Analysis Status")}
            <Badge variant={statusChip.variant}>
              {isStreaming && <span className="stage__spin keep-motion h-2.5 w-2.5" aria-hidden="true" />}
              {statusChip.label}
            </Badge>
          </p>
        </div>

        <div className="mt-10 space-y-10">
          {analysisData.status === "error" && analysisData.error && (
            <div role="alert" className="flex items-start gap-3 rounded-md bg-bad-soft p-4">
              <XCircle className="mt-0.5 h-5 w-5 flex-shrink-0 text-bad" aria-hidden="true" />
              <div>
                <h2 className="text-base text-bad">{t("Analysis Error")}</h2>
                <p className="mt-1 text-sm text-ink-2">{analysisData.error}</p>
              </div>
            </div>
          )}

          <AnalysisReport
            results={streamingResults}
            isStreaming={isStreaming}
            sessionId={analysisData.sessionId}
            reviews={reviews}
            onReviewed={setReviews}
          />

          {analysisData.status === "complete" && analysisData.sessionId && can("view_source") && (
            <Suspense fallback={null}>
              <ContractIDE key={analysisData.sessionId} sessionId={analysisData.sessionId} results={streamingResults} reviews={reviews} onReviewed={setReviews} />
            </Suspense>
          )}
        </div>
      </main>

      {assistant && <RefactorChatbot
        sessionId={analysisData.sessionId}
        reviews={reviews}
        vulnerableFunctions={flaggedFunctions(streamingResults)}
      />}
    </div>
  );
};

export default Analysis;
