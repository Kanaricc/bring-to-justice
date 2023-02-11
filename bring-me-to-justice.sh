#!/bin/bash

justice_list=()
failed_list=()
failed_log=()

request_confirm(){
    echo "$1 [Y/n]"
    read ans
    if [[ -z $ans ]]; then
        ans='y'
    fi
    if [[ $ans == 'y' || $ans == 'Y' ]]; then
        return 0
    else
        return 1
    fi
}

judge(){
    echo ""
    echo "========== 没想到捅了 $1 ==========="
    echo ""
    justice_list+=($1)
}
log_fail(){
    failed_log+=("$1 \t $2")
    failed_list+=($1)
}

do_cargo(){
    if [[ ! -f "$HOME/.cargo/config" ]]; then
        cat <<EOT > $HOME/.cargo/config
[source.crates-io]
replace-with = 'tuna'

[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"
EOT
        if [[ $? -ne 0 ]]; then
            log_fail cargo "failed to write config"
        fi
    else
        echo "cargo config exists. skip cargo."
        log_fail cargo "you have already edited cargo config"
    fi
    
}

do_pip(){
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
    if [[ $? -ne 0 ]]; then
        log_fail pip "failed to execute pip and set global indexl url"
    fi
}

do_conda(){
    if [[ ! -f "$HOME/.condarc" ]]; then
        cat <<EOT > $HOME/.condarc
channels:
  - defaults
show_channel_urls: true
default_channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
custom_channels:
  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  msys2: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  bioconda: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  menpo: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch-lts: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  simpleitk: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
EOT
        if [[ $? -ne 0 ]]; then
            log_fail conda "failed to write config"
        fi
    else
        echo "condarc exists. skip conda."
        log_fail conda "you have already edited condarc"
    fi
}

do_npm(){
    npm config set registry https://registry.npmmirror.com
    if [[ $? -ne 0 ]]; then
        log_fail npm "failed to set npm registry"
    fi
}

do_perl(){
    if [[ ! -f "$HOME/.cpan/CPAN/MyConfig.pm" ]]; then
        if [[ $(perl -v) =~ v([0-9]+).([0-9]+).([0-9]+) ]]; then
            if [[ ${BASH_REMATCH[1]} -ge 5 && ${BASH_REMATCH[2]} -ge 36 ]]; then
                PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'CPAN::HandleConfig->edit("pushy_https", 0); CPAN::HandleConfig->edit("urllist", "unshift", "https://mirrors.tuna.tsinghua.edu.cn/CPAN/"); mkmyconfig'
                if [[ $? -ne 0 ]]; then
                    log_fail perl
                fi
            else
                PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'CPAN::HandleConfig->edit("urllist", "unshift", "https://mirrors.tuna.tsinghua.edu.cn/CPAN/"); mkmyconfig'
                if [[ $? -ne 0 ]]; then
                    log_fail perl
                fi
            fi
        else
            echo "cannot get version of perl. failed to bring perl to justice."
            if [[ $? -ne 0 ]]; then
                log_fail perl "failed to get version of perl"
            fi
        fi
    else
        echo "cpan config exists. skip cpan."
        log_fail perl "you have already generated cpan config"
    fi
}

# main
if request_confirm "你这是违法行为，是否跟我去自首？"; then
    echo "走，跟我去自首"
else
    echo "自首失败"
    exit
fi

if type cargo >/dev/null 2>&1; then
    judge cargo
    do_cargo
fi
if type pip >/dev/null 2>&1; then
    judge pip
    do_pip
fi
if type conda >/dev/null 2>&1; then
    judge conda
    do_conda
fi
if type npm >/dev/null 2>&1; then
    judge npm
    do_npm
fi
if type perl >/dev/null 2>&1; then
    judge perl
    do_perl
fi

RED='\033[0;31m'
NC='\033[0m' # No Color
echo -e "$RED 任何换源 终将绳之以法 $NC"
for e in "${justice_list[@]}"; do
    echo -e "\t$e"
done

if [[ ${#failed_list[@]} -eq 0 ]]; then
    echo -e "$RED 所有小贼均被缉拿归案 $NC"
else
    echo -e "$RED 在逃名单 $NC"
    for e in "${failed_log[@]}"; do
        echo -e "\t$e"
    done
    echo "请查看错误信息以获取帮助"
fi