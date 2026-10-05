#!/bin/bash
# Offline test for the model builders: bundles models/*.lua with a mock Roblox API and builds every model.
# Needs the Luau CLI: https://github.com/luau-lang/luau/releases (put `luau` on PATH or next to this script).
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
MODELS="$HERE/../../models"
OUT="$HERE/bundle.lua"
LUAU="$(command -v luau || echo "$HERE/luau")"
{
  echo 'local Mock = (function()'; cat "$HERE/mock.lua"; echo 'end)()'
  echo 'local G = Mock.globals'
  echo 'local Vector3, CFrame, Color3, Enum, Instance, Vector2 = G.Vector3, G.CFrame, G.Color3, G.Enum, G.Instance, G.Vector2'
  echo 'local ColorSequence, NumberSequence, NumberSequenceKeypoint, NumberRange, typeof = G.ColorSequence, G.NumberSequence, G.NumberSequenceKeypoint, G.NumberRange, G.typeof'
  echo 'local shared = {Name = "Shared"}'
  echo 'local models = {Name = "Models", Parent = shared}'
  echo 'shared.Models = models'
  echo 'shared.GameConfig = {Name = "GameConfig", Parent = shared}'
  echo 'for _, n in ipairs({"ModelKit", "CropModels", "PetModels", "ItemModels"}) do models[n] = {Name = n, Parent = models} end'
  echo 'local MOD, cache = {}, {}'
  echo 'local function require(node) if cache[node] == nil then cache[node] = MOD[node.Name](node) end return cache[node] end'
  echo 'MOD["GameConfig"] = function(script)'; cat "$HERE/GameConfig.lua"; echo 'end'
  for n in ModelKit CropModels PetModels ItemModels; do
    echo "MOD[\"$n\"] = function(script)"; cat "$MODELS/$n.lua"; echo 'end'
  done
  echo 'local function Load(n) return require(n == "GameConfig" and shared.GameConfig or models[n]) end'
  cat "$HERE/run.lua"
} > "$OUT"
"$LUAU" "$OUT"
