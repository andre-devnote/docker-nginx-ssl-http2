# docker-nginx-ssl

Imagem do Nginx 1.14.0 (stable) para ambientes de desenvolvimento com HTTPS e HTTP2. Permite definir host e porta do PHP-fpm via variáveis de ambiente (graças ao [confd](https://github.com/kelseyhightower/confd))

## Como usar?

### Acessando por "https://localhost"

Nesse caso o certificado (ssl-cert) é instalado diretamente na imagem. Vai funcionar, porém aparecerá uma mensagem de "certificado inválido" no navegador.

No Google Chrome é possível alterar uma configuração para que esse aviso não apareça no locahost:

    - Acesse `chrome://flags/#allow-insecure-localhost`
    - Altere o valor desse parâmetro para 'Enabled'
    - Reinicie o navegador

Depois, basta criar o container...

`docker run --rm -d -p 443:443 nginx-ssl:14.0-dev`

... e acessar https://localhost pelo Chrome.


### Acessando por "https://domain.local"

Para isso será necessário instalar o [mkcert](https://github.com/FiloSottile/mkcert) na sua máquina. [Veja aqui como instalar](https://github.com/FiloSottile/mkcert#installation).

Após a instalação, vá até o diretório do seu projeto (nesse exemplo vou usar /dir/do/projeto) e rode o comando abaixo ("domain.local" pode ser qualquer domínio):

`mkcert domain.local`

**Importante**: O mkcert suporta wildcards (como *.domain.local), mas nos meus testes o certificado gerado não funcionou no container.

Após executar o comando acima serão criados dois arquivos no diretório atual (domain.local.pem e domain.local-key.pem) que serão montados como volumes do container.

Para fazer o apontamento do host será necessário definir um IP fixo para o container, e isso só é possível criando antes uma rede:

`docker network create -d bridge --subnet 175.25.0.0/16 teste_rede_docker`

Vamos supor que o IP do container será 175.25.1.1. Adicione a linha abaixo no seu arquivo de hosts (no Linux fica em /etc/hosts)

`175.25.1.1 domain.local`

E por fim, para criar o container (substitua */dir/do/projeto* pelo diretório do seu projeto):
```
docker run --rm -d \
    -v /dir/do/projeto:/var/www/html/public \
    -v /dir/do/projeto/domain.local.pem:/etc/ssl/certs/cert.pem \
    -v /dir/do/projeto/domain.local-key.pem:/etc/ssl/private/cert-key.pem \
    --network teste_rede_docker \
    --ip 175.25.1.1 \
    --name container_nginx \
    nginx-ssl:14.0-dev
```

Agora basta acessar https://domain.local. O domínio estara apontando para o container e com um certificado SSL válido para a sua máquina.

#### PHP-fpm

Para trabalhar com PHP você precisa criar outro container com o PHP-fpm. Eu uso [essa imagem](https://github.com/andre-devnote/docker-php-fpm-laravel) para projetos com Laravel. É preciso definir as variável de ambiente PHPFPM_HOSTNAME (se for diferente de 127.0.0.1) e PHPFPM_PORT (se for diferente de 9000):

```
docker run -d \
    -v /dir/do/projeto:/var/www/html \
    --name container_laravel devnote/php-fpm-laravel:7.2-dev

docker run --rm -d \
    -v /dir/do/projeto:/var/www/html \
    -p 443:443 \
    --link container_laravel -e PHPFPM_HOSTNAME=container_laravel \
    --name container_nginx nginx-ssl:14.0-dev
```

Você pode acessar https://localhost/fpm-status para testar.

Se o container do PHP-fpm tiver um IP fixo, substitua `--link container_laravel -e PHPFPM_HOSTNAME container_laravel` por `-e PHPFPM_HOSTNAME IP.DO.CONTAINER`.


## O que está instalado na imagem?

Além de algumas dependências (curl, openssl, gnupg1, apt-transport-https, ca-certificates, gettext-base) também está instaldo:

- [nginx 1.14.0 (stable)](http://nginx.org/en/download.html)

- [ssl-cert](https://packages.debian.org/stretch/ssl-cert)

- [procps](https://packages.debian.org/stretch/procps)

- [confd](https://github.com/kelseyhightower/confd)

O timezone do sistema está configurado como "America/Sao_Paulo".

