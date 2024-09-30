# Дипломный практикум в Yandex.Cloud - Сергей Ситкарёв

<details>
    <summary><h1>Задание</h1></summary>
	
  * [Цели:](#цели)
  * [Этапы выполнения:](#этапы-выполнения)
     * [Создание облачной инфраструктуры](#создание-облачной-инфраструктуры)
     * [Создание Kubernetes кластера](#создание-kubernetes-кластера)
     * [Создание тестового приложения](#создание-тестового-приложения)
     * [Подготовка cистемы мониторинга и деплой приложения](#подготовка-cистемы-мониторинга-и-деплой-приложения)
     * [Установка и настройка CI/CD](#установка-и-настройка-cicd)
  * [Что необходимо для сдачи задания?](#что-необходимо-для-сдачи-задания)
  * [Как правильно задавать вопросы дипломному руководителю?](#как-правильно-задавать-вопросы-дипломному-руководителю)

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

---
## Цели:

1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.
2. Запустить и сконфигурировать Kubernetes кластер.
3. Установить и настроить систему мониторинга.
4. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.
5. Настроить CI для автоматической сборки и тестирования.
6. Настроить CD для автоматического развёртывания приложения.

---
## Этапы выполнения:


### 1. Создание облачной инфраструктуры

Для начала необходимо подготовить облачную инфраструктуру в ЯО при помощи [Terraform](https://www.terraform.io/).

Особенности выполнения:

- Бюджет купона ограничен, что следует иметь в виду при проектировании инфраструктуры и использовании ресурсов;
Для облачного k8s используйте региональный мастер(неотказоустойчивый). Для self-hosted k8s минимизируйте ресурсы ВМ и долю ЦПУ. В обоих вариантах используйте прерываемые ВМ для worker nodes.

Предварительная подготовка к установке и запуску Kubernetes кластера.

1. Создайте сервисный аккаунт, который будет в дальнейшем использоваться Terraform для работы с инфраструктурой с необходимыми и достаточными правами. Не стоит использовать права суперпользователя
2. Подготовьте [backend](https://www.terraform.io/docs/language/settings/backends/index.html) для Terraform:  
   а. Рекомендуемый вариант: S3 bucket в созданном ЯО аккаунте(создание бакета через TF)
   б. Альтернативный вариант:  [Terraform Cloud](https://app.terraform.io/)  
3. Создайте VPC с подсетями в разных зонах доступности.
4. Убедитесь, что теперь вы можете выполнить команды `terraform destroy` и `terraform apply` без дополнительных ручных действий.
5. В случае использования [Terraform Cloud](https://app.terraform.io/) в качестве [backend](https://www.terraform.io/docs/language/settings/backends/index.html) убедитесь, что применение изменений успешно проходит, используя web-интерфейс Terraform cloud.

Ожидаемые результаты:

1. Terraform сконфигурирован и создание инфраструктуры посредством Terraform возможно без дополнительных ручных действий.
2. Полученная конфигурация инфраструктуры является предварительной, поэтому в ходе дальнейшего выполнения задания возможны изменения.

---
### 2. Создание Kubernetes кластера

На этом этапе необходимо создать [Kubernetes](https://kubernetes.io/ru/docs/concepts/overview/what-is-kubernetes/) кластер на базе предварительно созданной инфраструктуры.   Требуется обеспечить доступ к ресурсам из Интернета.

Это можно сделать двумя способами:

1. Рекомендуемый вариант: самостоятельная установка Kubernetes кластера.  
   а. При помощи Terraform подготовить как минимум 3 виртуальных машины Compute Cloud для создания Kubernetes-кластера. Тип виртуальной машины следует выбрать самостоятельно с учётом требовании к производительности и стоимости. Если в дальнейшем поймете, что необходимо сменить тип инстанса, используйте Terraform для внесения изменений.  
   б. Подготовить [ansible](https://www.ansible.com/) конфигурации, можно воспользоваться, например [Kubespray](https://kubernetes.io/docs/setup/production-environment/tools/kubespray/)  
   в. Задеплоить Kubernetes на подготовленные ранее инстансы, в случае нехватки каких-либо ресурсов вы всегда можете создать их при помощи Terraform.
2. Альтернативный вариант: воспользуйтесь сервисом [Yandex Managed Service for Kubernetes](https://cloud.yandex.ru/services/managed-kubernetes)  
  а. С помощью terraform resource для [kubernetes](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_cluster) создать **региональный** мастер kubernetes с размещением нод в разных 3 подсетях      
  б. С помощью terraform resource для [kubernetes node group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_node_group)
  
Ожидаемый результат:

1. Работоспособный Kubernetes кластер.
2. В файле `~/.kube/config` находятся данные для доступа к кластеру.
3. Команда `kubectl get pods --all-namespaces` отрабатывает без ошибок.

---
### 3. Создание тестового приложения

Для перехода к следующему этапу необходимо подготовить тестовое приложение, эмулирующее основное приложение разрабатываемое вашей компанией.

Способ подготовки:

1. Рекомендуемый вариант:  
   а. Создайте отдельный git репозиторий с простым nginx конфигом, который будет отдавать статические данные.  
   б. Подготовьте Dockerfile для создания образа приложения.  
2. Альтернативный вариант:  
   а. Используйте любой другой код, главное, чтобы был самостоятельно создан Dockerfile.

Ожидаемый результат:

1. Git репозиторий с тестовым приложением и Dockerfile.
2. Регистри с собранным docker image. В качестве регистри может быть DockerHub или [Yandex Container Registry](https://cloud.yandex.ru/services/container-registry), созданный также с помощью terraform.

---
### 4. Подготовка cистемы мониторинга и деплой приложения

Уже должны быть готовы конфигурации для автоматического создания облачной инфраструктуры и поднятия Kubernetes кластера.  
Теперь необходимо подготовить конфигурационные файлы для настройки нашего Kubernetes кластера.

Цель:
1. Задеплоить в кластер [prometheus](https://prometheus.io/), [grafana](https://grafana.com/), [alertmanager](https://github.com/prometheus/alertmanager), [экспортер](https://github.com/prometheus/node_exporter) основных метрик Kubernetes.
2. Задеплоить тестовое приложение, например, [nginx](https://www.nginx.com/) сервер отдающий статическую страницу.

Способ выполнения:
1. Воспользоваться пакетом [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus), который уже включает в себя [Kubernetes оператор](https://operatorhub.io/) для [grafana](https://grafana.com/), [prometheus](https://prometheus.io/), [alertmanager](https://github.com/prometheus/alertmanager) и [node_exporter](https://github.com/prometheus/node_exporter). Альтернативный вариант - использовать набор helm чартов от [bitnami](https://github.com/bitnami/charts/tree/main/bitnami).

2. Если на первом этапе вы не воспользовались [Terraform Cloud](https://app.terraform.io/), то задеплойте и настройте в кластере [atlantis](https://www.runatlantis.io/) для отслеживания изменений инфраструктуры. Альтернативный вариант 3 задания: вместо Terraform Cloud или atlantis настройте на автоматический запуск и применение конфигурации terraform из вашего git-репозитория в выбранной вами CI-CD системе при любом комите в main ветку. Предоставьте скриншоты работы пайплайна из CI/CD системы.

Ожидаемый результат:
1. Git репозиторий с конфигурационными файлами для настройки Kubernetes.
2. Http доступ к web интерфейсу grafana.
3. Дашборды в grafana отображающие состояние Kubernetes кластера.
4. Http доступ к тестовому приложению.

---
### 5. Установка и настройка CI/CD

Осталось настроить ci/cd систему для автоматической сборки docker image и деплоя приложения при изменении кода.

Цель:

1. Автоматическая сборка docker образа при коммите в репозиторий с тестовым приложением.
2. Автоматический деплой нового docker образа.

Можно использовать [teamcity](https://www.jetbrains.com/ru-ru/teamcity/), [jenkins](https://www.jenkins.io/), [GitLab CI](https://about.gitlab.com/stages-devops-lifecycle/continuous-integration/) или GitHub Actions.

Ожидаемый результат:

1. Интерфейс ci/cd сервиса доступен по http.
2. При любом коммите в репозиторие с тестовым приложением происходит сборка и отправка в регистр Docker образа.
3. При создании тега (например, v1.0.0) происходит сборка и отправка с соответствующим label в регистри, а также деплой соответствующего Docker образа в кластер Kubernetes.

---
## Что необходимо для сдачи задания?

1. Репозиторий с конфигурационными файлами Terraform и готовность продемонстрировать создание всех ресурсов с нуля.
2. Пример pull request с комментариями созданными atlantis'ом или снимки экрана из Terraform Cloud или вашего CI-CD-terraform pipeline.
3. Репозиторий с конфигурацией ansible, если был выбран способ создания Kubernetes кластера при помощи ansible.
4. Репозиторий с Dockerfile тестового приложения и ссылка на собранный docker image.
5. Репозиторий с конфигурацией Kubernetes кластера.
6. Ссылка на тестовое приложение и веб интерфейс Grafana с данными доступа.
7. Все репозитории рекомендуется хранить на одном ресурсе (github, gitlab)

</details>

# Решение

### 1. Создание облачной инфраструктуры

Создание сервисного аккаунта

[service-account.tf](https://github.com/SSitkarev/devops_diploma/blob/main/terraform/service-account.tf)

![Задание1](https://github.com/SSitkarev/devops_diploma/blob/main/img/1-2.jpg)

Подготовка backend (s3 bucket) для Terraform

[tfbucket.tf](https://github.com/SSitkarev/devops_diploma/blob/main/terraform/tfbucket.tf)

![Задание1](https://github.com/SSitkarev/devops_diploma/blob/main/img/1-3.jpg)

Создание VPC с подсетями в разных зонах доступности

[vpc.tf](https://github.com/SSitkarev/devops_diploma/blob/main/terraform/vpc.tf)

![Задание1](https://github.com/SSitkarev/devops_diploma/blob/main/img/1-4.jpg)

Результаты выполнения **terraform apply**

![Задание1](https://github.com/SSitkarev/devops_diploma/blob/main/img/1-1.jpg)

Далее, согласно [документации](https://yandex.cloud/ru/docs/tutorials/infrastructure-management/terraform-state-storage#set-up-backend) , необходимо добавить в providers.tf секцию 

```
  backend "s3" {
    endpoint = "https://storage.yandexcloud.net"
    bucket = "tfbucket"
    region = "ru-central1"
    key    = "tfbucket/terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
    }
```
	
задать в качестве новых переменных ACCESS_KEY и SECRET_KEY, которые будут получены в результате создания bucket.

И заново инициализировать Terraform командой *terraform init -backend-config="access_key=$ACCESS_KEY" -backend-config="secret_key=$SECRET_KEY"*

![Задание1](https://github.com/SSitkarev/devops_diploma/blob/main/img/1-5.jpg)

![Задание1](https://github.com/SSitkarev/devops_diploma/blob/main/img/1-6.jpg)

### 2. Создание Kubernetes кластера

Создание кластера из 3 нод

[kube-cluster.tf](https://github.com/SSitkarev/devops_diploma/blob/main/terraform/kube-cluster.tf)

![Задание2](https://github.com/SSitkarev/devops_diploma/blob/main/img/2-1.jpg)

Проверка доступа по ssh с использованием ключа

![Задание2](https://github.com/SSitkarev/devops_diploma/blob/main/img/2-2.jpg)

**Примечание**
На ночь виртуальные машины отключал, сменились IP адреса

При создании kubernetes кластера на подготовленных нодах, используем рекомендованный вариант с kubespray.
Для этого выполним следующие действия:

- Клонируем репозиторий [kubespray](https://github.com/kubernetes-sigs/kubespray.git) 
- Создаём inventory.yaml файл для ansible при помощи terraform. Для этого создаём [ресурс](https://github.com/SSitkarev/devops_diploma/blob/main/terraform/ansible.tf) и [шаблон](https://github.com/SSitkarev/devops_diploma/blob/main/terraform/inventory.tftpl)
- При помощи [документации](https://github.com/kubernetes-sigs/kubespray?tab=readme-ov-file#usage) и полученного [inventory.yaml](https://github.com/SSitkarev/devops_diploma/blob/main/terraform/inventory.yaml), создаём kubernetes кластер
```
ansible-playbook -i inventory/k8scluster/inventory.yaml --become --become-user=root -u ubuntu --private-key=~/.ssh/id_ed25519 cluster.yml
```

Кластер готов

![Задание2](https://github.com/SSitkarev/devops_diploma/blob/main/img/2-3.jpg)

Далее для управления кластером скопируем конфиг kubernetes */etc/kubernetes/admin.conf* в папку пользователя *~/.kube/config*

Теперь убедимся, что кластер доступен и работает

![Задание2](https://github.com/SSitkarev/devops_diploma/blob/main/img/2-4-1.jpg)

### 3. Создание тестового приложения

Подготовим минимальный конфиг для отображения статичной веб-страницы
```
<html>
    <body>
        <h1>diploma_site</h1>
        <img src="image.jpg"/>
    </body>
</html>
```

Подготовим Dockerfile
```
FROM nginx
COPY site_content/ /usr/share/nginx/html/
EXPOSE 80
```
Создадим отдельный репозиторий на GitHub для хранения кода

[Отдельный репозиторий с nginx конфигом](https://github.com/SSitkarev/diploma_site/tree/main)

Соберём docker образ 
```
docker build -t ssitkarev/diploma_site:1.0 .
```
И загрузим собранный образ в DockerHub
```
docker push ssitkarev/diploma_site:1.0
```

[Регистри с собранным docker image](https://hub.docker.com/repository/docker/ssitkarev/diploma_site/general)

### 4. Подготовка cистемы мониторинга и деплой приложения

Систему мониторинга разворачиваем с помощью helm чартов, для этого выполняем следующие шаги:

- Копируем репозиторий 
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```
- Для того, чтобы веб интерфейс Grafana был доступен извне кластера, сохраняем локально дефолтные параметры чарта 
```
helm show values prometheus-community/kube-prometheus-stack > helm-values.yaml
```
- Вносим изменения для сервиса grafana, а именно указываем тип **type: NodePort** и значение порта **nodePort: 30000**

- И выполняем развертывание с использованием измененного конфига 
```
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack --create-namespace -n monitoring -f helm-values.yaml
```
![Задание4](https://github.com/SSitkarev/devops_diploma/blob/main/img/4-1.jpg)

- Проверим доступность интерфейса Grafana и данных в нём.

![Задание4](https://github.com/SSitkarev/devops_diploma/blob/main/img/4-2.jpg)

Для запуска веб-приложения создадим [deploymnet](https://github.com/SSitkarev/devops_diploma/blob/main/web-app/deployment.yaml) и [service](https://github.com/SSitkarev/devops_diploma/blob/main/web-app/service.yaml) для его доступности извне.

![Задание4](https://github.com/SSitkarev/devops_diploma/blob/main/img/4-3.jpg)

- Проверим доступность веб-приложения извне:

![Задание4](https://github.com/SSitkarev/devops_diploma/blob/main/img/4-4.jpg)

### 5. Установка и настройка CI/CD

В качестве CI/CD инструмента будем использовать Jenkins. Установку производим, согласно официальной [документации](https://www.jenkins.io/doc/book/installing/linux/)

После установки убедимся, что веб-интерфейс доступен

![Задание5](https://github.com/SSitkarev/devops_diploma/blob/main/img/5-1.jpg)

В ходе первоначальной настройки, нам необходимо подключить плагины **Mailer**, **Git**, **GitHub**, **Kubernetes CLI Plugin**, **Kubernetes Credentials Plugin**

Далее спрячем чувствительные данные при помощи Credentials Plugin

![Задание5](https://github.com/SSitkarev/devops_diploma/blob/main/img/5-2.jpg)

Выполним настройку подключения jenkins к нашему Kubernetes кластеру (в качестве Credentials использовался kubeconfig файл)

![Задание5](https://github.com/SSitkarev/devops_diploma/blob/main/img/5-3.jpg)

![Задание5](https://github.com/SSitkarev/devops_diploma/blob/main/img/5-4.jpg)

Создадим job по шаблону freestyle project

![Задание5](https://github.com/SSitkarev/devops_diploma/blob/main/img/5-5.jpg)

![Задание5](https://github.com/SSitkarev/devops_diploma/blob/main/img/5-6.jpg)

![Задание5](https://github.com/SSitkarev/devops_diploma/blob/main/img/5-7.jpg)

В репозитории тестового приложения на GitHub добавим webhook

![Задание5](https://github.com/SSitkarev/devops_diploma/blob/main/img/5-8.jpg)

Теперь внесём изменения в index.html файл

```
<html>
    <body>
        <h1>diploma_site+pipeline</h1>
        <img src="image.jpg"/>
    </body>
</html>
```

И зафиксируем номер версии 1.2 в файле version и закоммитим изменения.

В репозитории на GitHub мы видим коммит 

![Задание5](https://github.com/SSitkarev/devops_diploma/blob/main/img/5-9.jpg)

В истории отправки webhooks так же видно, что после данного коммита, был отправлен хук, и он был успешно доставлен

![Задание5](https://github.com/SSitkarev/devops_diploma/blob/main/img/5-11.jpg)

![Задание5](https://github.com/SSitkarev/devops_diploma/blob/main/img/5-10.jpg)

Jenkins так же показывает, что job прошел успешно

![Задание5](https://github.com/SSitkarev/devops_diploma/blob/main/img/5-12.jpg)

В DockerHub появилась новая версия тестового образа, номер версии совпадает с указанной при коммите

![Задание5](https://github.com/SSitkarev/devops_diploma/blob/main/img/5-13.jpg)

И, наконец, веб-страница отображает изменения, внесённые в **index.html**