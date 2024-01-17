# Домашнее задание к занятию 2 «Работа с Playbook», Лебедев А.И., fops-10

## Подготовка к выполнению

1. * Необязательно. Изучите, что такое [ClickHouse](https://www.youtube.com/watch?v=fjTNS2zkeBs) и [Vector](https://www.youtube.com/watch?v=CgEhyffisLY).
2. Создайте свой публичный репозиторий на GitHub с произвольным именем или используйте старый.
3. Скачайте [Playbook](./playbook/) из репозитория с домашним заданием и перенесите его в свой репозиторий.
4. Подготовьте хосты в соответствии с группами из предподготовленного playbook.

## Основная часть

1. Подготовьте свой inventory-файл `prod.yml`.
2. Допишите playbook: нужно сделать ещё один play, который устанавливает и настраивает [vector](https://vector.dev). Конфигурация vector должна деплоиться через template файл jinja2. От вас не требуется использовать все возможности шаблонизатора, просто вставьте стандартный конфиг в template файл. Информация по шаблонам по [ссылке](https://www.dmosk.ru/instruktions.php?object=ansible-nginx-install). не забудьте сделать handler на перезапуск vector в случае изменения конфигурации!
3. При создании tasks рекомендую использовать модули: `get_url`, `template`, `unarchive`, `file`.
4. Tasks должны: скачать дистрибутив нужной версии, выполнить распаковку в выбранную директорию, установить vector.
5. Запустите `ansible-lint site.yml` и исправьте ошибки, если они есть.
6. Попробуйте запустить playbook на этом окружении с флагом `--check`.
7. Запустите playbook на `prod.yml` окружении с флагом `--diff`. Убедитесь, что изменения на системе произведены.
8. Повторно запустите playbook с флагом `--diff` и убедитесь, что playbook идемпотентен.
9. Подготовьте README.md-файл по своему playbook. В нём должно быть описано: что делает playbook, какие у него есть параметры и теги. Пример качественной документации ansible playbook по [ссылке](https://github.com/opensearch-project/ansible-playbook). Так же приложите скриншоты выполнения заданий №5-8
10. Готовый playbook выложите в свой репозиторий, поставьте тег `08-ansible-02-playbook` на фиксирующий коммит, в ответ предоставьте ссылку на него.

---

## Решение:  

- Машина, на которую я собирался устанавливать инфраструктуру, была развернута при помощи Vagrant с образом RHEL8, т.к. в плэйбуках используется нэймспейс для этой архитектуры.

- ansible-lint был установлен отдельно при помощи пакетного менеджера pip, т.к. у меня не было его в коробке вместе с ансибл

- Изначально, я хотел использовать конструкция, которая скачивает и распаковывает пакет с Vector, но потом отказался от этой конструкции, собственно, и lint говорил, что у меня там есть неточности:

  ```
  root@ashost:/home/vagrant/homeworks/08-ansible-02-playbook/playbook# ansible-lint site.yml
WARNING: PATH altered to include /usr/bin
[DEPRECATION WARNING]: Ansible will require Python 3.8 or newer on the
controller starting with Ansible 2.12. Current version: 3.7.3 (default, Oct 11
2023, 09:51:27) [GCC 8.3.0]. This feature will be removed from ansible-core in
version 2.12. Deprecation warnings can be disabled by setting
deprecation_warnings=False in ansible.cfg.
WARNING  Overriding detected file kind 'yaml' with 'playbook' for given positional argument: site.yml
WARNING  Listing 4 violation(s) that are fatal
command-instead-of-module: tar used in place of unarchive module
site.yml:57 Task/Handler: Extract and Install Vector

no-changed-when: Commands should not change things if nothing needs doing
site.yml:57 Task/Handler: Extract and Install Vector

command-instead-of-module: tar used in place of unarchive module
site.yml:86 Task/Handler: Extract and Install Vector

no-changed-when: Commands should not change things if nothing needs doing
site.yml:86 Task/Handler: Extract and Install Vector

You can skip specific rules or tags by adding them to your configuration file:
# .ansible-lint
warn_list:  # or 'skip_list' to silence them completely
  - command-instead-of-module  # Using command rather than module
  - no-changed-when  # Commands should not change things if nothing needs doing

Finished with 4 failure(s), 0 warning(s) on 1 files.  
```

- Дополнительную переменную для версии Vector, я добавил в vars папки clickhouse, т.к. устанавливал все на одной машине.

- При использовании флага --check, у меня валился плэйбук уже на моменте использования rescue. Т.к. я сразу не понял, что, наверное, это нормально, я немного переделал плэйбук (это все вы можете видеть в **playbook/site.yml**), добавил отдельную переменную для одного компонента и вынес его установку в отдельный таск, а rescue вообще закомментил.
После этого, check побежал, но снова свалился при установке скаченных компонентов.

- После этого, я начал экспериментировать уже с установкой на живой машине.

- Методом различных проб (отображены в плэйбуке), я так и не смог победить вот эту ошибку:

```
TASK [Install Vector] **************************************************************************************************************************************************
fatal: [clickhouse-01]: FAILED! => {"changed": false, "msg": "Failed to validate GPG signature for vector-0.35.0-1.x86_64"}  
```

- Она возникала, как при установке одного из компонентом кликхауса, так и при установке вектора. Пришлось поменять нэймспейс на другой и добавить --nogpgcheck -

```
    - name: Install clickhouse packages
      become: true
      ansible.builtin.command: >
        yum install -y --nogpgcheck
        clickhouse-common-static-{{ clickhouse_version }}.rpm
        clickhouse-client-{{ clickhouse_version }}.rpm
        clickhouse-server-{{ clickhouse_version }}.rpm  
```

- Далее, у меня возникла трудность с поиском простого, но рабочего конфиг-файла для Vector, но и его удалось найти (см. **templates/vector.yaml.j2**)

- Собственно, слегка увлекшись, я сделал --diff уже после того, как мой плэйбук успешно отработал на удаленной машине:

```
root@ashost:/home/vagrant/homeworks/08-ansible-02-playbook/playbook# ansible-playbook -i ./inventory/prod.yml site.yml --diff
[DEPRECATION WARNING]: Ansible will require Python 3.8 or newer on the controller starting with Ansible 2.12. Current version: 3.7.3 (default, Oct 11 2023, 09:51:27)
[GCC 8.3.0]. This feature will be removed from ansible-core in version 2.12. Deprecation warnings can be disabled by setting deprecation_warnings=False in ansible.cfg.

PLAY [Install Clickhouse] **********************************************************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************************************************************
ok: [clickhouse-01]

TASK [Get clickhouse distrib] ******************************************************************************************************************************************
ok: [clickhouse-01] => (item=clickhouse-client)
ok: [clickhouse-01] => (item=clickhouse-server)

TASK [Get common-static distrib] ***************************************************************************************************************************************
ok: [clickhouse-01] => (item=clickhouse-common-static)

TASK [get clickhouse GPG-key] ******************************************************************************************************************************************
ok: [clickhouse-01]

TASK [Import ClickHouse GPG key] ***************************************************************************************************************************************
changed: [clickhouse-01]

TASK [Install clickhouse packages] *************************************************************************************************************************************
changed: [clickhouse-01]

TASK [Flush handlers] **************************************************************************************************************************************************

RUNNING HANDLER [Start clickhouse service] *****************************************************************************************************************************
changed: [clickhouse-01]

TASK [Create database] *************************************************************************************************************************************************
ok: [clickhouse-01]

PLAY [Install Vector] **************************************************************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************************************************************
ok: [clickhouse-01]

TASK [Get Vector distrib] **********************************************************************************************************************************************
ok: [clickhouse-01]

TASK [Install Vector] **************************************************************************************************************************************************
changed: [clickhouse-01]

TASK [Configure Vector] ************************************************************************************************************************************************
ok: [clickhouse-01]

PLAY RECAP *************************************************************************************************************************************************************
clickhouse-01              : ok=12   changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  
```

- Собственно, все идемпотентно.

- Я оставлю комментарии к некоторым строкам прямо в плэйбуке.


