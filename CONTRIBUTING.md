# How to port a game

Please read `.opencode/skills/mt-to-haxe/SKILL.md` which explains globally how to port a game

- New games must go in a new directory: `resources/hx/games/<gamename>`
- When porting a new game, the folder name should be in lowercase with no special char (`K-Slash!` -> `kslash`; `Kanji's Gaiden` -> `kanjisgaiden`)
- You should add the game to the `compile.hxml` file
- The Game class should implement `kado.GameInterface`
- The Game class should be exposed as `Game<GameInPascalCase>`: (`K-Slash!` -> `GameKSlash` // `Kanji's Gaiden` -> `GameKanjisGaiden`)
- If Manager.hx exists, delete the file, it is not needed
- Add a `NEW_GEN_SCALE` cnostant (`public static var NEW_GEN_SCALE = 3`) in either `Cs` or `Game` file, and use it wherever it is needed. We are reproducing the games that were in 300x300 format in the new gen format 900x900. So every value, speed, distance, etc should be multiplied by this ratio.

# About assets:

- FFDec (JPEXS) for swf decompilation + asset export is needed. Export size should be 300% in PNG format.
- TexturePacker (pro) is needed, the KadokadeoManager loads the game spritesheets from the starting file `public/assets/img/content/<gamename>/<gamename>-0.json`. Multipack must be enabled with destination file : `<gamename>-{n}.json`. i.e. `kslash-{n}.json`
- Please follow the file/folder convention :

| File/Folder                                                          | Usage                                                    |
| -------------------------------------------------------------------- | -------------------------------------------------------- |
| `public/assets/img/content/<gamename>/`                              | Root directory of game files                             |
| `public/assets/img/content/<gamename>/src`                           | Source directory for assets files, used in TexturePacker |
| `public/assets/img/content/<gamename>/<gamename>.tps`                | TexturePacker source file                                |
| `public/assets/img/content/<gamename>/<gamename>-<number>.json\|png` | TexturePacker built files                                |
| `public/assets/img/gfx/artwork/<gamename>.jpg`                       | Artwork of the game. Please use an upscale tool          |

# TODO: How to update the code with PIXI api
