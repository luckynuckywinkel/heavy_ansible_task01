# Домашнее задание к занятию 14 «Средство визуализации Grafana», Лебедев А.И., FOPS-10

### Задание 1

1. Используя директорию [help](./help) внутри этого домашнего задания, запустите связку prometheus-grafana.

```
cd 10-monitoring-03-grafana/help
docker-compose up
docker ps -a
```
![1](img/1.png)  

Для правильного использования функционала, были прокинуты порты. Prometheus - 9090. Nodexporter - 9191.  


1. Зайдите в веб-интерфейс grafana, используя авторизационные данные, указанные в манифесте docker-compose.

![2](img/2.png)  


2. Подключите поднятый вами prometheus, как источник данных.

![3](img/3.png)  


## Задание 2

Создайте Dashboard и в ней создайте Panels:

- утилизация CPU для nodeexporter (в процентах, 100-idle):

```
avg without (cpu)(irate(node_cpu_seconds_total{job="nodeexporter",mode="idle"}[1m]))
```


- CPULA 1/5/15;

```
node_load1{job="nodeexporter"}
node_load5{job="nodeexporter"}
node_load15{job="nodeexporter"}
```


- количество свободной оперативной памяти;

```
node_memory_MemFree_bytes{job='nodeexporter'}
```


- количество места на файловой системе.

```
node_filesystem_avail_bytes{instance="nodeexporter:9100", job="nodeexporter", mountpoint="/"}
```

![4](img/4.png)  



## Задание 3

1. Создайте для каждой Dashboard подходящее правило alert — можно обратиться к первой лекции в блоке «Мониторинг».
2. В качестве решения задания приведите скриншот вашей итоговой Dashboard.

## Решение:    

![5](img/5.png) 



## Задание 4

1. Сохраните ваш Dashboard.Для этого перейдите в настройки Dashboard, выберите в боковом меню «JSON MODEL». Далее скопируйте отображаемое json-содержимое в отдельный файл и сохраните его.
2. В качестве решения задания приведите листинг этого файла.

## Решение:  

1. Тот самый *.json -



---
