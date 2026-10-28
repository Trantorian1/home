{pkgs, ...}: {
  # Replaces the old dev/opencode/ activation script (mkdir -p + cp -r of a
  # writeTextFile into ~/.config/opencode/opencode.json) with a Hjem copy
  # entry: the JSON is rendered from an attrset via pkgs.formats.json and
  # copied (not symlinked) to ~/.config/opencode/opencode.json. With
  # clobberFiles = true it is refreshed on every activation, exactly like the
  # old cp -r script did. On-disk bytes differ from the old file only in key
  # order (the JSON generator sorts keys) but are semantically identical.
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
