# MacNotes

MacNotes é um app pessoal para macOS que vive ao redor do notch do MacBook. Ele mantém as suas Tasks e mostra a Focus Session em andamento para que o trabalho atual fique visível sem abrir uma janela.

Requer macOS 14 ou posterior.

## Português (Brasil)

### Abrir o app

O build do MacNotes não é assinado nem notarizado. No macOS 15 ou posterior, Control-clique → Abrir foi removido e não funciona para contornar o Gatekeeper. Para abrir o app, use o único caminho disponível:

1. Abra **Ajustes do Sistema** → **Privacidade e Segurança**.
2. Na seção **Segurança**, clique em **Abrir Mesmo Assim**.
3. Confirme a abertura e autentique-se quando o macOS pedir.

Se o macOS disser que o app está *danificado*, o app não está danificado: ele recebeu o atributo de quarentena. Com o app em `/Applications`, remova esse atributo no Terminal:

```sh
xattr -dr com.apple.quarantine /Applications/MacNotes.app
```

### Encerrar o app

Para parar o MacNotes completamente, abra o Planner pelo botão `⤢` no Notch Panel, abra **Ajustes** pelo botão de engrenagem e, na seção **MacNotes**, clique em **Quit MacNotes** e confirme. O app salva os seus dados e deixa de executar o Notch Panel, o atalho global e qualquer Focus Session.

Com o Planner aberto, você também pode escolher **MacNotes → Quit MacNotes** na barra de menus ou pressionar `⌘Q`.

### Seus dados

Nada sai da sua máquina: não há conta, servidor nem telemetria. As Tasks e preferências são arquivos JSON simples, que você pode abrir e ler em:

```
~/Library/Containers/com.devbrigante.macnotes/Data/Library/Application Support/MacNotes/
```

Os arquivos `tasks.json` e `settings.json` são uma promessa verificável: você pode inspecioná-los e fazer backup deles com o Finder ou o Terminal.

### Calendário

O MacNotes pode mostrar eventos do Calendário ao lado das Tasks de um dia. O macOS não oferece uma permissão de Calendário somente para leitura: é necessário conceder acesso completo para que o app leia os eventos. O MacNotes os trata apenas como contexto — não cria, altera nem apaga eventos, não os converte em Tasks e não bloqueia horários. Essa é uma disciplina do app, diferente da promessa verificável de que seus dados não deixam a máquina.

## English

MacNotes is a personal macOS app that lives around the MacBook notch. It keeps your Tasks and shows the current Focus Session, so the work in progress stays visible without opening a window.

It requires macOS 14 or later.

### Opening the app

The MacNotes build is unsigned and unnotarized. On macOS 15 and later, Control-click → Open was removed and does not bypass Gatekeeper. The only available path is:

1. Open **System Settings** → **Privacy & Security**.
2. In the **Security** section, click **Open Anyway**.
3. Confirm that you want to open the app and authenticate when macOS asks.

If macOS says the app is *damaged*, it is not damaged: it has a quarantine attribute. With the app in `/Applications`, remove that attribute in Terminal:

```sh
xattr -dr com.apple.quarantine /Applications/MacNotes.app
```

### Quitting the app

To stop MacNotes completely, open the Planner with the `⤢` button in the Notch Panel, open **Settings** with the gear button, then click **Quit MacNotes** in the **MacNotes** section and confirm. The app saves your data and stops the Notch Panel, global hotkey, and any Focus Session.

With the Planner open, you can also choose **MacNotes → Quit MacNotes** from the menu bar or press `⌘Q`.

### Your data

Nothing leaves your machine: there is no account, server, or telemetry. Tasks and preferences are plain JSON files that you can open and read at:

```
~/Library/Containers/com.devbrigante.macnotes/Data/Library/Application Support/MacNotes/
```

The `tasks.json` and `settings.json` files make this a verifiable promise: you can inspect and back them up with Finder or Terminal.

### Calendar

MacNotes can show Calendar events beside a day's Tasks. macOS does not provide a read-only Calendar permission: full access is required for the app to read events. MacNotes treats those events only as context—it never creates, changes, or deletes them, turns them into Tasks, or blocks time. That is an app discipline, unlike the verifiable promise that your data never leaves the machine.
