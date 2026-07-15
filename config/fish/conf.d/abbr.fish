# These always run last and override whatever
function fish_user_key_bindings
    bind ctrl-space 'commandline -i " "'
end

abbr -a b bun
abbr -a v nvim
abbr -a p pnpm
abbr -a cc "claude --dangerously-skip-permissions"
abbr -a ccr "claude --dangerously-skip-permissions --resume"
abbr -a cx "codex --dangerously-bypass-approvals-and-sandbox"
abbr -a cxr "codex --dangerously-bypass-approvals-and-sandbox resume"
abbr -a oc opencode
abbr -a td tuxedo
abbr -a tda "tuxedo add"
abbr -a tdl "tuxedo list"
abbr -a ls "eza -la --icons --group-directories-first --git"

abbr -a gs "git status"
abbr -a gd "git diff"
abbr -a gl "git log"
abbr -a gck "git checkout"
abbr -a grh "git reset --hard && git clean -fd"
abbr -a gcl "git clean -fdx"

abbr -a ga "git add ."
abbr -a gc --position anywhere --set-cursor 'git commit -m "%"'
abbr -a gp "git push origin HEAD"
abbr -a gwip "ga && gc wip && gp"
abbr -a gca "git commit --amend --no-edit"

abbr -a gss "git add . && git stash"
abbr -a gsl "git stash list"
abbr -a gsp "git stash pop"

abbr qwencpp "llama-server -hf ggml-org/Qwen2.5-Coder-7B-Q8_0-GGUF --port 8012 -ngl 99 \
--flash-attn on -ub 1024 -b 1024 --ctx-size 16384 --cache-reuse 256"

abbr gptoss "llama-server -hf ggml-org/gpt-oss-20b-GGUF --port 8013 -ngl 99 \
--flash-attn on --ctx-size 65536 --cache-type-k q8_0 --cache-type-v q8_0 --jinja --n-cpu-moe 8 --host 0.0.0.0"

abbr gptosslite "llama-server -hf ggml-org/gpt-oss-20b-GGUF --port 8013 -ngl 99 \
--flash-attn on --ctx-size 65536 --cache-type-k q8_0 --cache-type-v q8_0 --jinja --n-cpu-moe 12 --host 0.0.0.0"

abbr qwenfim "llama-server -hf ggml-org/Qwen2.5-Coder-1.5B-Q8_0-GGUF --port 8012 -ngl 99 \
--flash-attn on -ub 1024 -b 1024 --ctx-size 16384 --cache-reuse 256"

abbr gemmav "llama-server -hf unsloth/gemma-4-E2B-it-GGUF:Q4_K_M \
--mmproj-url https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/main/mmproj-F16.gguf \
--port 8014 -ngl 99 --flash-attn on --ctx-size 8192 --jinja --reasoning off --host 0.0.0.0"

abbr gemmavhq "llama-server -hf unsloth/gemma-4-E4B-it-GGUF:Q4_K_M \
--mmproj-url https://huggingface.co/unsloth/gemma-4-E4B-it-GGUF/resolve/main/mmproj-F16.gguf \
--port 8014 -ngl 99 --flash-attn on --ctx-size 8192 --jinja --reasoning off --host 0.0.0.0"

abbr zeta "llama-server -hf bartowski/zed-industries_zeta-2-GGUF:Q6_K --port 8000 -ngl 99 \
--flash-attn on -ub 1024 -b 1024 --ctx-size 16384 --cache-reuse 256"
