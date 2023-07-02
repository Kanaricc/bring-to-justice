import os
import shutil
import re
from distutils import spawn

home_dir=os.path.expanduser('~')

def request_confirm(prompt:str,default_yes=True):
    option_prompt='[Y/n]' if default_yes else '[y/N]'
    inp=input(f"{prompt} {option_prompt}").lower().strip()
    if inp=="":inp='y' if default_yes else 'n'
    if inp in ['yes']:inp='y'
    if inp in ['no']:inp='n'
    
    return inp=='y'

def check_reg_in_file(path:str,pattern:str):
    if not os.path.exists(path):
        return False
    with open(path,'r') as f:
        ex=re.findall(pattern,f.read())
    return len(ex)>0

def exe_exists(executable:str):
    return spawn.find_executable(executable) is not None

def backup(path:str):
    if not os.path.exists(path):return
    assert os.path.isfile(path),f"{path} is not a file"
    tgt=path+'.backup'
    shutil.copy(path,tgt)

def append_to_file(path:str,val:str):
    with open(path,'a') as f:
        f.write('\n')
        f.write(val)

results=[]

def log_res(name:str,status:str,msg:str=""):
    results.append((name,status,msg))

def do_cargo():
    cargo_path=os.path.join(home_dir,'.cargo','config')
    if check_reg_in_file(cargo_path,r'source'):
        log_res('cargo','pass','source has been already configured.')
        return
    backup(cargo_path)
    append_to_file(cargo_path,"""
[source.crates-io]
replace-with = 'tuna'

[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"
""")
    log_res('cargo','ok')

def do_pip():
    res=os.system("pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple")
    if res==0:log_res('pip','ok')
    else: log_res('pip','failed')

def do_conda():
    path=os.path.join(home_dir,'.condarc')
    if check_reg_in_file(path,r'default_channels'):
        log_res('conda','pass','source has been already configured.')
        return
    backup(path)
    append_to_file(path,"""
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
""")
    log_res('conda','ok')

def do_npm():
    res=os.system("npm config set registry https://registry.npmmirror.com")
    if res==0:log_res('npm','ok')
    else: log_res('npm','failed')


if __name__=='__main__':
    mapping=[
        ('cargo',do_cargo),
        ('pip',do_pip),
        ('conda',do_conda),
        ('npm',do_npm),
    ]

    for k,v in mapping:
        if exe_exists(k):
            if request_confirm(f"要带 {k} 去自首吗？"):
                v()
    
    if len(results)>0:
        print("任何换源 终将绳之以法")
        for item in results:
            print("\t".join(item))
    else:
        print("失望离开")