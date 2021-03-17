from ubuntu:latest

RUN apt update -y \
&& apt upgrade -y \
&& apt install -y zsh git curl \
&& apt autoremove -y

COPY . /opt/dotfiles
WORKDIR /opt/dotfiles
