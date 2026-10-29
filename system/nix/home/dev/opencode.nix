{pkgs, ...}: {
  xdg.config.files."opencode/opencode.json" = {
    type = "copy";
    generator = (pkgs.formats.json {}).generate "opencode-config";
    value = {
      "$schema" = "https://opencode.ai/config.json";
      model = "unsloth/ornith-1.5";
      providers.unsloth = {
        name = "Unsloth";
        package = "@opencode/ai/providers/openai-compatible";
        settings = {
          baseURL = "http://10.0.2.10:8888/v1";
          apiKey = "{env:UNSLOTH_API_KEY}";
        };
        models = {
          flint = {
            name = "Recursive Flint";
            modelID = "flint-GGUF:Q8_0";
            capabilities = {
              tools = true;
              input = [
                "text"
                "image"
              ];
              output = ["text"];
            };
            limit.context = 262144;
          };
          "qwen3.8" = {
            name = "Qwen3.8 (local)";
            modelID = "Qwen3.8-27B-GGUF:UD-Q8_K_XL";
            capabilities = {
              tools = true;
              input = [
                "text"
                "image"
              ];
              output = ["text"];
            };
            limit.context = 262144;
          };
          "ornith-1.5" = {
            name = "Ornith-1.5 (local)";
            modelID = "Ornith-1.5-35B-A3B-GGUF:Q8_0";
            capabilities = {
              tools = true;
              input = [
                "text"
                "image"
              ];
              output = ["text"];
            };
            limit.context = 262144;
          };
        };
      };
    };
  };
}
