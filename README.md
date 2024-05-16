# 安装MariaDB
确保你的机器上有MariaDB，如果没有，按以下命令安装
以下是在 Debian 10 上安装 MariaDB 的步骤：

## 更新软件包索引：

 在终端中运行以下命令来确保你的软件包索引是最新的：

    ```bash
    sudo apt update
    ```

## 安装 MariaDB 服务器软件包：

在终端中运行以下命令来安装 MariaDB 服务器软件包：

    ```bash
    sudo apt install mariadb-server
    ```
安装过程中会提示你设置 root 密码。设置完成后，MariaDB 服务器会继续安装和配置。

### 启动 MariaDB 服务：

安装完成后，MariaDB 服务器应该已经启动。你可以使用以下命令来检查 MariaDB 服务器的状态：

    ```bash
    sudo systemctl status mariadb
    ```
如果 MariaDB 服务器未运行，你可以使用以下命令手动启动它：

    ```bash
    sudo systemctl start mariadb
    ```
    
现在，MariaDB 应该已经在你的 Debian 10 系统上安装完成并且可以正常使用了。

---

# 一键部署WordPress脚本

这个脚本允许你在 Debian 系统上轻松部署 WordPress，并使用 MariaDB 作为数据库。脚本提供了一种简单而快速的方法来设置你的 WordPress 博客，并允许你自定义博客端口。

## 使用方法

1. **下载脚本**

    ```bash
    wget https://raw.githubusercontent.com/githubmissyang/auto_wordpress_script/main/wordpress_debian_10.sh
    ```

2. **赋予执行权限**

    ```bash
    chmod +x wordpress_debian_10.sh
    ```

3. **执行脚本**

    ```bash
    ./wordpress_debian_10.sh
    ```

    按照提示逐步输入所需的信息：MariaDB root 密码、WordPress 数据库用户、WordPress 数据库密码。如果你希望使用默认的数据库名和本地IP地址，只需按 Enter 键即可。

4. **按照提示完成安装**

    运行脚本后，按照提示完成 WordPress 的安装。你可以通过浏览器访问 `http://your_server_ip:blog_port`（如果使用默认端口，则为 `http://your_server_ip`）来访问你的 WordPress 博客。

## 注意事项

- 在执行脚本之前，请确保你有足够的权限，并且已经备份了你的数据。
- 脚本只在 Debian 系统上进行了测试，可能无法在其他系统上正常运行。
- 请仔细阅读脚本中的注释，并根据你的需求进行相应的修改。

## 贡献

如果你发现任何 bug 或者有改进的建议，请随时提出 issue 或者提交 pull request。

## 许可证

这个项目使用 [MIT 许可证](LICENSE)。

--- 

在上面的说明中，替换 `<your-username>` 和 `<your-repo-name>` 为你的 GitHub 用户名和仓库名称。此外，注意提供适当的许可证信息，以便其他用户知道他们可以如何使用你的代码。
