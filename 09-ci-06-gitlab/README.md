# Домашнее задание к занятию 12 «GitLab», Лебедев А.И., FOPS-10

## Подготовка к выполнению


1. Или подготовьте к работе Managed GitLab от yandex cloud [по инструкции](https://cloud.yandex.ru/docs/managed-gitlab/operations/instance/instance-create) .
Или создайте виртуальную машину из публичного образа [по инструкции](https://cloud.yandex.ru/marketplace/products/yc/gitlab ) .
2. Создайте виртуальную машину и установите на нее gitlab runner, подключите к вашему серверу gitlab  [по инструкции](https://docs.gitlab.com/runner/install/linux-repository.html) .

3. (* Необязательное задание повышенной сложности. )  Если вы уже знакомы с k8s попробуйте выполнить задание, запустив gitlab server и gitlab runner в k8s  [по инструкции](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/gitlab-containers). 

4. Создайте свой новый проект.
5. Создайте новый репозиторий в GitLab, наполните его [файлами](./repository).
6. Проект должен быть публичным, остальные настройки по желанию.

## Выполнение подготовки:  

- Заведем машину на YC. Ресурсов дадим ей не много, т.к. сборка не сложная, установим туда гитлаб-раннер и зарегистрируем:

![1](img/1.JPG)  

- Напишем тестовый пайплайн, чтобы проверить работу раннера и прогоним его:

```
stages:
  - test

test_runner:
  stage: test
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  script: 
    - echo "hello world"
```


![2](img/3.JPG)  

- Все отлично. Можно переходить к основной части.



## Основная часть

### DevOps

В репозитории содержится код проекта на Python. Проект — RESTful API сервис. Ваша задача — автоматизировать сборку образа с выполнением python-скрипта:

1. Образ собирается на основе [centos:7](https://hub.docker.com/_/centos?tab=tags&page=1&ordering=last_updated).
2. Python версии не ниже 3.7.
3. Установлены зависимости: `flask` `flask-jsonpify` `flask-restful`.
4. Создана директория `/python_api`.
5. Скрипт из репозитория размещён в /python_api.
6. Точка вызова: запуск скрипта.
7. При комите в любую ветку должен собираться docker image с форматом имени hello:gitlab-$CI_COMMIT_SHORT_SHA . Образ должен быть выложен в Gitlab registry или yandex registry.

### DevOps часть:  

- Для начала я написал доккерфайл:

```
FROM centos:7


RUN yum update -y && \

    yum install -y python3 python3-pip && \
    yum clean all && \
    rm -rf /var/cache/yum



RUN pip3 install flask


RUN mkdir /python_api
COPY python-api.py /python_api


WORKDIR /python_api


CMD ["python3", "/python_api/python-api.py"]
```

- На данном этапе, пайплайн выглядит вот так:

```
image: docker:latest

variables:
  DOCKER_TLS_CERTDIR: ""
  DOCKER_DRIVER: overlay2

stages:
  - build

before_script:
  - unset DOCKER_HOST
  - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

build_and_publish_image:
  stage: build
  script:
    - docker build --build-arg PYTHON_VERSION=3.7 -t $CI_REGISTRY_IMAGE:gitlab-$CI_COMMIT_SHORT_SHA .
    - docker push $CI_REGISTRY_IMAGE:gitlab-$CI_COMMIT_SHORT_SHA
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  tags:
    - netology
```

- Пришлось подкрутить кое-какие настройки доккера на раннере, но все вышло. Пайп проходит, продукт падает в реджистри гитлаба:

![3](img/4.JPG)  

![4](img/5.JPG)



### Product Owner

Вашему проекту нужна бизнесовая доработка: нужно поменять JSON ответа на вызов метода GET `/rest/api/get_info`, необходимо создать Issue в котором указать:

1. Какой метод необходимо исправить.
2. Текст с `{ "message": "Already started" }` на `{ "message": "Running"}`.
3. Issue поставить label: feature.

### Product Owner часть:  

- Создадим Issue и опишем его:

![5](img/6.JPG)

### Developer

Пришёл новый Issue на доработку, вам нужно:

1. Создать отдельную ветку, связанную с этим Issue.
2. Внести изменения по тексту из задания.
3. Подготовить Merge Request, влить необходимые изменения в `master`, проверить, что сборка прошла успешно.

### Developer часть:    

- Все было сделано. + увидел некоторые косяки, что не заметил до этого и тоже исправил.
- Dockerfile теперь выглядит вот так:

```
ROM centos:7


RUN yum update -y && \

    yum install -y python3 python3-pip && \
    yum clean all && \
    rm -rf /var/cache/yum



RUN pip3 install flask flask_restful flask_jsonpify


RUN mkdir /python_api
COPY python-api.py /python_api


WORKDIR /python_api

EXPOSE 5290
CMD ["python3", "/python_api/python-api.py"]
```




### Tester

Разработчики выполнили новый Issue, необходимо проверить валидность изменений:

1. Поднять докер-контейнер с образом `python-api:latest` и проверить возврат метода на корректность.
2. Закрыть Issue с комментарием об успешности прохождения, указав желаемый результат и фактически достигнутый.

### Tester часть:    

- Дополнил пайплайн. Добавил несколько джоб. Первая - просто делает сборку при запросе на МР. Вторая - собирает и тестит поменялись ли в итоге значения:

```
image: docker:latest

variables:
  DOCKER_TLS_CERTDIR: ""
  DOCKER_DRIVER: overlay2

stages:
  - test
  - pre_merge_build
  - build
   
pre_merge_build:
  stage: pre_merge_build
  image: docker    
  script:
    - docker build --build-arg PYTHON_VERSION=3.7 -t $CI_REGISTRY_IMAGE/gitlab-$CI_COMMIT_SHORT_SHA:latest .
  rules:
    - if: '$CI_COMMIT_BRANCH != "main" && $CI_PIPELINE_SOURCE == "merge_request_event"'
  tags:
    - netology

test_image:
  stage: test
  image: docker
  before_script:
    - apk add --update curl && rm -rf /var/cache/apk/*
  script:
    - docker build --build-arg PYTHON_VERSION=3.7 -t $CI_REGISTRY_IMAGE/gitlab-$CI_COMMIT_SHORT_SHA:latest .
    - docker run -d -p 5290:5290 $CI_REGISTRY_IMAGE/gitlab-$CI_COMMIT_SHORT_SHA:latest
    - sleep 10
    - curl http://178.154.225.231:5290/get_info 
  rules:
    - if: $CI_PIPELINE_SOURCE == "web"
  tags:
    - netology
  
build_and_publish_image:
  stage: build
  before_script:
    - unset DOCKER_HOST
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build --build-arg PYTHON_VERSION=3.7 -t $CI_REGISTRY_IMAGE:gitlab-$CI_COMMIT_SHORT_SHA .
    - docker push $CI_REGISTRY_IMAGE:gitlab-$CI_COMMIT_SHORT_SHA
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: manual
  tags:
    - netology
  needs:
    - job: test_image
```

P.S. if: $CI_PIPELINE_SOURCE == "web" - вот так я сделал потому что перемудрил с условиями и уже очень торопился и джоба тупила страшно,что пришлось аж прописать внешний ip раннера, т.к. по локалхосту не достукивалось.  
Собственно, тут должны были быть условия, что при завершенном МР в ветку main оно стартует.  

![6](img/7.JPG)  

![7](img/8.JPG)  

- Ну и ссылка на репу:

https://gitlab.com/luckynuckywinkel/gitlab_homework   

Раннер на YC я убил, если что.  

---

  






