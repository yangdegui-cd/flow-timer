# GitHub OAuth 设置指南

## 1. 创建 GitHub OAuth 应用

1. 访问 [GitHub Developer Settings](https://github.com/settings/developers)
2. 点击 "New OAuth App"
3. 填写应用信息：
   - **Application name**: FlowTimer (或您的应用名称)
   - **Homepage URL**: `http://localhost:5174` (开发环境)
   - **Application description**: FlowTimer 任务调度系统
   - **Authorization callback URL**: `http://localhost:3000/auth/github/callback`

4. 点击 "Register application"
5. 记录 `Client ID` 和 `Client Secret`

## 2. 配置环境变量

在 `.env` 文件中设置：

```bash
# GitHub OAuth配置
GITHUB_CLIENT_ID=your_actual_github_client_id
GITHUB_CLIENT_SECRET=your_actual_github_client_secret

# 前端URL (重要：OAuth回调后重定向使用)
FRONTEND_URL=http://localhost:5174
```

## 3. 生产环境配置

### 后端配置
```bash
# 生产环境示例
GITHUB_CLIENT_ID=your_production_github_client_id
GITHUB_CLIENT_SECRET=your_production_github_client_secret
FRONTEND_URL=https://your-frontend-domain.com
```

### GitHub OAuth App 生产环境设置
- **Homepage URL**: `https://your-frontend-domain.com`
- **Authorization callback URL**: `https://your-backend-domain.com/auth/github/callback`

## 4. 功能说明

### OAuth 登录流程
1. 用户点击 "使用 GitHub 登录" 按钮
2. 跳转到 GitHub 授权页面
3. 用户授权后，GitHub 重定向到后端回调地址
4. 后端验证授权码，创建或关联用户账号
5. 生成 JWT token，重定向到前端成功页面
6. 前端保存 token 并跳转到系统首页

### 账号绑定流程
1. 已登录用户访问 "账号绑定" 页面
2. 点击 "绑定 GitHub 账号" 按钮
3. 完成 GitHub 授权
4. 后端将 GitHub 账号关联到当前用户
5. 前端显示绑定成功，返回设置页面

## 5. 安全注意事项

1. **环境变量保护**: 绝不要将 `GITHUB_CLIENT_SECRET` 提交到代码仓库
2. **HTTPS**: 生产环境必须使用 HTTPS
3. **域名验证**: GitHub OAuth 会验证回调域名，确保配置正确
4. **token 安全**: JWT token 存储在 localStorage，定期清理过期 token

## 6. 测试验证

### 开发环境测试
1. 启动后端服务：`rails server` (默认端口 3000)
2. 启动前端服务：`npm run dev` (默认端口 5174)
3. 访问 `http://localhost:5174/auth/login`
4. 点击 "使用 GitHub 登录" 进行测试

### 检查要点
- [ ] GitHub OAuth App 配置正确
- [ ] 环境变量设置正确
- [ ] 前后端服务正常运行
- [ ] 网络可以访问 GitHub API
- [ ] 浏览器允许弹窗和重定向

## 7. 故障排除

### 常见问题
1. **"redirect_uri_mismatch"**: 检查 GitHub OAuth App 的回调 URL 配置
2. **"invalid_client"**: 检查 `GITHUB_CLIENT_ID` 和 `GITHUB_CLIENT_SECRET`
3. **跨域问题**: 确保后端 CORS 配置允许前端域名
4. **重定向失败**: 检查 `FRONTEND_URL` 环境变量

### 调试方法
1. 查看浏览器开发者工具的网络标签页
2. 查看后端日志：`tail -f log/development.log`
3. 检查 GitHub OAuth App 的设置页面
4. 验证环境变量是否正确加载：`rails console` -> `ENV['GITHUB_CLIENT_ID']`