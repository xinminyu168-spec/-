# GitHub 云端构建与试玩

本工程通过 GitHub Actions 运行 Godot 4.6.3 的真实 Web 导出，再发布到 GitHub Pages。网页内运行的是本项目的 Godot 游戏，和编辑器使用相同的场景与 GDScript。

- 源码仓库： https://github.com/xinminyu168-spec/nantianmen-godot
- 目标试玩地址（首次成功发布后可用）： https://xinminyu168-spec.github.io/nantianmen-godot/
- 构建记录： https://github.com/xinminyu168-spec/nantianmen-godot/actions

## 后续更新

修改工程并推送到 `main`，GitHub Actions 会自动执行：安装官方 Godot → 导入场景 → 运行机制测试 → 导出 Web → 发布 Pages。也可在 Actions 中选择 `Test, export Godot and deploy Pages`，点击 `Run workflow` 手动运行。

仓库的 Settings → Pages 应使用 `GitHub Actions` 作为 Build and deployment 来源。

## 网页导出设置

`export_presets.cfg` 已配置 Web 预设：

- 单线程，`variant/thread_support=false`，适合 GitHub Pages，不需要额外的跨源隔离响应头。
- 兼容渲染器，浏览器需支持 WebAssembly 和 WebGL 2。
- 固定 540×960 逻辑画布，按浏览器窗口等比适配。
- 相对资源路径，支持仓库子路径 `/nantianmen-godot/`。
- 不启用离线服务工作线程，减少更新后的缓存干扰。
- 随工程打包了约 100 KB 的 Noto CJK 字体子集，保证网页上的中文不依赖系统字体；许可和来源保留于 `assets/fonts/OFL-Noto-CJK.txt`。

第一次打开需要下载 Godot WebAssembly 运行时和游戏包，加载耗时受网络影响。浏览器中若出现点击启动提示，点击后即可进入游戏。手机浏览器支持触摸按钮；横屏会留边。

## 核对构建版本

网页根目录的 `build-info.json` 记录 GitHub 源码 commit、Godot 版本以及每个导出文件的 SHA-256。Actions 中还保留名为 `nantianmen-godot-web` 的可下载构建产物。

不要把 `.godot/`、导出模板、账号凭据或本地导出密钥上传到仓库。当前 `.gitignore` 已排除这些文件。
