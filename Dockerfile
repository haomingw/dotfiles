from ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris

RUN apt update -y \
&& apt upgrade -y \
&& apt install -y \
  zsh \
  git \
  curl \
  sudo \
  xz-utils \
  lsb-release \
  software-properties-common \
&& apt autoremove -y

RUN useradd -m docker -s $(which zsh) \
&& usermod -aG sudo docker \
&& echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER docker

COPY . /opt/dotfiles
WORKDIR /opt/dotfiles

RUN bash install.sh vim \
&& bash install.sh faster-zsh \
&& bash install.sh tmux-docker
