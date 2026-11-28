import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { FileUpload } from "@/components/FileUpload";
import Header from "@/components/Header";
import { Loader2, Search } from "lucide-react";
import { PipelineTrail } from "@/components/Pipeline";
import { PointScan } from "@/components/scan/PointScan";
import { previewFromSource } from "@/components/scan/parseSolidity";
import { toast } from "sonner";
import { projectService } from "@/services/project";
import { tokenService, TokenSearchResult } from "@/services/token";
import { useT } from "@/i18n";
import { useAuth } from "@/contexts/AuthContext";

const Index = () => {
  const navigate = useNavigate();
  const t = useT();
  const { user, can } = useAuth();
  const [projectName, setProjectName] = useState("");
  const [selectedFile, setSelectedFile] = useState<{ file: File; content: string } | null>(null);
  const [isCreatingProject, setIsCreatingProject] = useState(false);

  // Token Search State
  const [activeTab, setActiveTab] = useState("upload");
  const [searchQuery, setSearchQuery] = useState("");
  const [isSearching, setIsSearching] = useState(false);
  const [searchResults, setSearchResults] = useState<TokenSearchResult[]>([]);
  const [selectedToken, setSelectedToken] = useState<TokenSearchResult | null>(null);
  const [tokenPlatforms, setTokenPlatforms] = useState<Record<string, string>>({});
  const [selectedPlatform, setSelectedPlatform] = useState<string>("");
  const [platformsLoaded, setPlatformsLoaded] = useState(false);

  const handleFileSelect = (file: File, content: string) => {
    setSelectedFile({ file, content });
  };

  const handleTokenSearch = async () => {
    if (!searchQuery.trim()) return;
    setIsSearching(true);
    setSearchResults([]);
    setSelectedToken(null);
    setTokenPlatforms({});
    setSelectedPlatform("");
    
    try {
        const results = await tokenService.searchTokens(searchQuery);
        setSearchResults(results);
    } catch (e) {
        toast.error(e instanceof Error && e.message ? t(e.message) : t("Failed to search token"));
    } finally {
        setIsSearching(false);
    }
  };
  
  const handleSelectToken = async (token: TokenSearchResult) => {
      setSelectedToken(token);
      setSelectedPlatform("");
      setTokenPlatforms({});
      setPlatformsLoaded(false);
      try {
          const platforms = await tokenService.getPlatforms(token.id);
          setTokenPlatforms(platforms);
          setPlatformsLoaded(true);
          const keys = Object.keys(platforms);
          if (keys.length > 0) setSelectedPlatform(keys[0]);
      } catch (e) {
          setSelectedToken(null);  // nothing to scan yet: let the user pick again instead of leaving a dead selection
          toast.error(e instanceof Error && e.message ? t(e.message) : t("Failed to load platforms"));
      }
  };

  const handleAnalyze = async () => {

    let fileToUse = selectedFile;
    
    if (activeTab === "search") {
        if (!selectedToken || !selectedPlatform) {
            toast.error(t("Pick a token and its chain."));
            return;
        }
        
        setIsCreatingProject(true);
        try {
            const address = tokenPlatforms[selectedPlatform];
            const tokenData = await tokenService.analyzeToken(selectedPlatform, address, selectedToken.name);
            
            const blob = new Blob([tokenData.source_code], { type: 'text/plain' });
            const file = new File([blob], tokenData.file_name, { lastModified: Date.now() });
            
            fileToUse = { 
                file: file, 
                content: tokenData.source_code 
            };
        } catch (e) {
             toast.error(e instanceof Error && e.message ? t(e.message) : t("Failed to fetch source code"));
             setIsCreatingProject(false);
             return;
        }
    } else {
        if (!fileToUse) {
            toast.error(t("Choose a .sol file."));
            return;
        }
        setIsCreatingProject(true);
    }
    
    try {
      // First create the project in the backend
      const project = await projectService.createProject({
        // Unnamed quick scans get the file's name plus the time: project names must be unique per user.
        name: projectName.trim() || `${fileToUse!.file.name} · ${new Date().toLocaleString(t.locale)}`,
        description: `Analysis project for ${fileToUse!.file.name}`
      });

      // Store project and file information
      sessionStorage.setItem(
        "contractAnalysis",
        JSON.stringify({
          projectId: project.id,
          projectName: project.name,
          fileName: fileToUse!.file.name,
          fileSize: fileToUse!.file.size,
          lastModified: fileToUse!.file.lastModified,
        })
      );

      // Store the actual file content
      sessionStorage.setItem("contractFile", fileToUse!.content);

      toast.success(t("Project created"));
      navigate("/analysis/live");
    } catch (error) {
      console.error("Error creating project:", error);
      toast.error(
        error instanceof Error 
          ? error.message 
          : t("Failed to create project. Please try again.")
      );
    } finally {
      setIsCreatingProject(false);
    }
  };

  const preview = useMemo(
    () => (activeTab === "upload" && selectedFile ? previewFromSource(selectedFile.content) : { functions: [], edges: [] }),
    [activeTab, selectedFile],
  );
  const previewCaption = activeTab === "upload" && selectedFile
    ? t("{f}: {n} functions declared, calls estimated from the source", { f: selectedFile.file.name, n: preview.functions.length })
    : activeTab === "search" && selectedToken
    ? t("{name}: the source is fetched when the analysis starts", { name: selectedToken.name })
    : t("Waiting for a contract");

  const noSupportedChain = Boolean(selectedToken) && platformsLoaded && Object.keys(tokenPlatforms).length === 0;
  const startDisabled = isCreatingProject || (activeTab === "upload" ? !selectedFile : (!selectedToken || !selectedPlatform));

  if (!can("upload")) {
    return (
      <div className="min-h-dvh bg-background">
        <Header />
        <main id="main" className="shell py-12 lg:py-16">
          <h1 className="text-4xl leading-none">{t("Smart Contract Analyzer")}</h1>
          <p className="mt-4 max-w-[60ch] text-ink-2">{t("Your role reads the reports of your workspace. A developer or the workspace admin uploads contracts; their reports are under Projects.")}</p>
        </main>
      </div>
    );
  }

  return (
    <div className="min-h-dvh bg-background">
      <Header />

      <main id="main" className="shell py-12 lg:py-16">
        <h1 className="text-4xl leading-none sm:text-5xl">{t("Smart Contract Analyzer")}</h1>
        <p className="mt-4 max-w-[52ch] text-lg text-ink-2">
          {t("Upload your Solidity contracts for comprehensive security analysis with real-time streaming results")}
        </p>

        <div className="mt-10 grid gap-10 lg:grid-cols-12 lg:gap-8">
        <div className="lg:col-span-7">
          <div className="ticks p-3">
            <PointScan
              functions={preview.functions}
              edges={preview.edges}
              phase={isCreatingProject ? "scanning" : "idle"}
              callouts={0}
              caption={previewCaption}
              label={t("Preview of the contract as points: {c}", { c: previewCaption })}
            />
          </div>
          <div className="mt-12">
            <h2 className="mb-6 text-sm text-muted-foreground">{t("What runs on your contract")}</h2>
            <PipelineTrail preview />
          </div>
        </div>

        <section className="panel self-start p-6 sm:p-8 lg:col-span-5" aria-labelledby="new-analysis-head">
          <h2 id="new-analysis-head" className="sr-only">{t("New Analysis")}</h2>
          {user?.policy && (
            <div className="mb-6 border-l-2 border-rule-2 pl-3 text-xs text-ink-2" role="note">
              <p>{t("Your contract is stored on the ScanGuard server and deleted automatically after {d} days. The detection models run on the server.", { d: user.policy.retention_days })}</p>
              <p className="mt-1">
                {user.llm_external && user.policy.external_llm
                  ? t("The code of each flagged function is sent to an external AI service to write explanations and fix suggestions. Your workspace admin can turn this off.")
                  : t("No code is sent to an external AI service.")}
              </p>
            </div>
          )}
          <div className="space-y-2">
            <Label htmlFor="project-name">{t("Project Name")} <span className="text-muted-foreground">({t("optional")})</span></Label>
            <Input
              id="project-name"
              placeholder={t("e.g., DeFi Protocol Audit")}
              value={projectName}
              onChange={(e) => setProjectName(e.target.value)}
            />
          </div>

          <Tabs defaultValue="upload" onValueChange={setActiveTab} className="mt-8 w-full">
            <TabsList className="grid w-full grid-cols-2">
              <TabsTrigger value="upload">{t("Upload File")}</TabsTrigger>
              <TabsTrigger value="search">{t("Search Token")}</TabsTrigger>
            </TabsList>

            <TabsContent value="upload" className="mt-6 space-y-2">
              <Label>{t("Upload Contract")}</Label>
              <FileUpload onFileSelect={handleFileSelect} />
            </TabsContent>

            <TabsContent value="search" className="mt-6 space-y-4">
              <div className="space-y-2">
                <Label htmlFor="token-search">{t("Token")}</Label>
                <div className="flex gap-2">
                  <Input
                    id="token-search"
                    placeholder={t("Search token by name or symbol (e.g. USDC, Uniswap)")}
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    onKeyDown={(e) => e.key === 'Enter' && handleTokenSearch()}
                  />
                  <Button onClick={handleTokenSearch} disabled={isSearching} variant="outline" size="icon" aria-label={t("Search token")} aria-busy={isSearching}>
                    {isSearching ? <Loader2 className="keep-motion h-4 w-4 animate-spin" /> : <Search className="h-4 w-4" />}
                  </Button>
                </div>
              </div>

              {searchResults.length > 0 && (
                <ul className="max-h-60 divide-y divide-rule overflow-y-auto rounded-md border border-rule" aria-label={t("Search results")}>
                  {searchResults.map(token => (
                    <li key={token.id}>
                      <button
                        type="button"
                        aria-pressed={selectedToken?.id === token.id}
                        className={`flex w-full items-center gap-3 px-3 py-2 text-left transition-colors duration-200 hover:bg-paper-3 ${selectedToken?.id === token.id ? 'bg-signal-soft' : ''}`}
                        onClick={() => handleSelectToken(token)}
                      >
                        {token.thumb && <img src={token.thumb} width={28} height={28} className="h-7 w-7 rounded-full" alt="" />}
                        <span>
                          <span className="block text-sm text-ink">{token.symbol.toUpperCase()}</span>
                          <span className="block text-xs text-muted-foreground">{token.name}</span>
                        </span>
                      </button>
                    </li>
                  ))}
                </ul>
              )}

              {selectedToken && !noSupportedChain && (
                <div className="land space-y-2">
                  <Label>{t("Select Chain")}</Label>
                  <Select value={selectedPlatform} onValueChange={setSelectedPlatform}>
                    <SelectTrigger aria-label={t("Chain")}>
                      <SelectValue placeholder={t("Select chain")} />
                    </SelectTrigger>
                    <SelectContent>
                      {Object.entries(tokenPlatforms).map(([chain, address]) => (
                        <SelectItem key={chain} value={chain}>
                          <span className="capitalize">{chain}</span>{' '}
                          <span className="code-text ml-2 text-xs text-muted-foreground">{address.substring(0, 8)}…{address.substring(address.length-6)}</span>
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              )}
            </TabsContent>
          </Tabs>

          <div className="mt-8 flex flex-wrap items-center gap-4 border-t border-rule pt-6">
            <Button
              onClick={handleAnalyze}
              size="lg"
              disabled={startDisabled}
              aria-busy={isCreatingProject}
            >
              {isCreatingProject ? (
                <>
                  <Loader2 className="keep-motion h-4 w-4 animate-spin" />
                  {t("Creating Project…")}
                </>
              ) : (
                t("Start Analysis")
              )}
            </Button>
            {startDisabled && !isCreatingProject && (
              <p className="text-sm text-muted-foreground">
                {activeTab === "upload" ? t("Choose a .sol file.") : noSupportedChain ? t("This token has no contract on Ethereum, the only network supported, so it cannot be scanned.") : t("Pick a token and its chain.")}
              </p>
            )}
          </div>
        </section>
        </div>
      </main>
    </div>
  );
};

export default Index;
