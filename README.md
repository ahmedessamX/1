# 1

## Codacy MCP Server Setup

This repository has been configured with the Codacy MCP (Model Context Protocol) Server, which enables code quality and security analysis through your IDE.

### Prerequisites

1. **Node.js & npm**: Ensure Node.js and npm are installed
   ```bash
   node -v
   npm -v
   ```

2. **Codacy Account Token**: Obtain your personal API token from your Codacy account
   - Go to your Codacy account → Access Management
   - Generate a new API token if you don't have one

### Configuration

The MCP server is configured in `.cursor/mcp.json`. To use it:

1. Replace `<YOUR_CODACY_TOKEN>` with your actual Codacy API token in `.cursor/mcp.json`:
   ```json
   {
     "mcpServers": {
       "codacy": {
         "command": "npx",
         "args": ["-y", "@codacy/codacy-mcp"],
         "env": {
           "CODACY_ACCOUNT_TOKEN": "your-actual-token-here"
         }
       }
     }
   }
   ```

2. If using VS Code or another IDE, you may need to copy this configuration to your IDE's settings file.

### Features

The Codacy MCP Server provides:
- Repository setup and management
- Code quality analysis (grade, issues, duplication, complexity, coverage)
- Security scanning (SAST, secrets detection, SCA, IaC scanning)
- File management and pull request analysis

### Troubleshooting

- If using Node Version Manager (NVM), ensure you reference the correct node binary in the configuration
- Make sure your Codacy token has the necessary permissions
- The server will automatically install the Codacy CLI when first run

For more information, visit the [Codacy MCP Server GitHub repository](https://github.com/codacy/codacy-mcp-server).