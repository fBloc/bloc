> Need already have `git`、`docker`、`docker-compose` installed.

1. Clone repo and switch to the directory：
    ```shell
    git clone https://github.com/fBloc/bloc.git && cd bloc
    ```

2. Run the install shell script
    ```shell
    /bin/bash ./startup.sh
    ```

3. If suc, should have seen below msg in the end:
    ```
    ******************************
    All ready!
    bloc-web address http://localhost:8083; default user: bloc; default password: maytheforcebewithyou
    bloc-backend-server address http://localhost:8080
    rabbitMQ address 127.0.0.1:5672; user blocRabbit, password blocRabbitPasswd
    ******************************
    ```
4. Suc!

> Remarks：
> - You can run command `/bin/bash ./shutdown.sh` to clear what have installed
