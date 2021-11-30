#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "vm.h"

#include <QFileDialog>
#include <QTextStream>
#include <QProcess>
#include <QMessageBox>
#include <cstdio>
#include <cstdlib>
#include <cstring>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
    , stream(&buf)
{
    ui->setupUi(this);
}

MainWindow::~MainWindow()
{
    std::system(("rm " + QDir::currentPath() + "/.__tmp.*").toStdString().c_str());
    delete ui;
}

void MainWindow::compileResult(int a) {
    QByteArray res = caller->readAllStandardOutput();
    centralWidget()->findChild<QTextEdit*>("infoEdit")->setText(QString::fromLocal8Bit(res));

    std::FILE* insFile = NULL;
    while ((insFile = std::fopen((QDir::currentPath() + "/.__tmp.vmasm").toStdString().c_str(),"r")) == NULL)
        ;
    vm_load_ins(insFile);
    centralWidget()->findChild<QListWidget*>("asmList")->clear();
    for (int i = 0;i < code_cnt; ++i) {
        QString line = QString("%1 %2").arg(mne_str[vcode[i].m]).arg(vcode[i].a);
        centralWidget()->findChild<QListWidget*>("asmList")->addItem(QString::number(i) + "    " + line);
    }
    std::fclose(insFile);

    caller->close();
}

void MainWindow::compile() {
    if (compilerPath == "") {
        centralWidget()->findChild<QTextEdit*>("infoEdit")->setText(QString("Can't find x0 compiler!"));
        QString path = QFileDialog::getOpenFileName(this, tr("Set x0 Compiler Path"),"x0 compiler(*)");
        printf("%s",path.toStdString().c_str());
        compilerPath = path;
        return;
    }

    centralWidget()->findChild<QTextEdit*>("infoEdit")->clear();
    QFile x0File(QDir::currentPath() + "/.__tmp.x0");
    x0File.open(QIODevice::WriteOnly | QIODevice::Text);
    QTextStream output(&x0File);
    output<<centralWidget()->findChild<QTextEdit*>("textEdit")->toPlainText();
    x0File.close();

    caller = new QProcess(this);
    connect(caller, SIGNAL(finished(int)), this, SLOT(compileResult(int)));
    caller->start(compilerPath, QStringList()<<QDir::currentPath() + "/.__tmp.x0"<<QDir::currentPath() + "/.__tmp.vmasm");
}

void MainWindow::prep_vm_inf() {
    vm_inf = std::fopen((QDir::currentPath() + "/.__tmp.in").toStdString().c_str(),"w");
    std::fprintf(vm_inf,"%s",centralWidget()->findChild<QTextEdit*>("inputEdit")->toPlainText().toStdString().c_str());
    std::fclose(vm_inf);
    vm_inf = std::fopen((QDir::currentPath() + "/.__tmp.in").toStdString().c_str(),"r");
}

void MainWindow::executeASM() {
    char vm_out[20] = {0 * 20};
    while (cur < code_cnt) {
        vm_step(vm_inf, vm_out);
        if (vm_out[0]) {
            stream<<vm_out;
            std::memset(vm_out,0,sizeof(vm_out));
        }
    }
    centralWidget()->findChild<QTextEdit*>("outputEdit")->append(buf);
    buf.clear();
    fclose(vm_inf);
}

void MainWindow::enter_step_mode() {
    step_mode = 1;
    centralWidget()->findChild<QTextEdit*>("inputEdit")->setReadOnly(1);
    centralWidget()->findChild<QTextEdit*>("textEdit")->setEnabled(0);
    centralWidget()->findChild<QPushButton*>("compileBtn")->setEnabled(0);
    menuBar()->setEnabled(0);
    centralWidget()->findChild<QListWidget*>("asmList")->setCurrentRow(0);
}

void MainWindow::leave_step_mode() {
    step_mode = 0;
    centralWidget()->findChild<QTextEdit*>("inputEdit")->setReadOnly(0);
    centralWidget()->findChild<QTextEdit*>("textEdit")->setEnabled(1);
    centralWidget()->findChild<QPushButton*>("compileBtn")->setEnabled(1);
    menuBar()->setEnabled(1);
    centralWidget()->findChild<QListWidget*>("stackList")->clear();
}

void MainWindow::runASM() {
    if (!code_cnt) {
        centralWidget()->findChild<QTextEdit*>("outputEdit")->setText(QString("NO VM ASM Code!"));
        return;
    }
    if (!step_mode) {
        centralWidget()->findChild<QTextEdit*>("outputEdit")->setText(QString(""));
        prep_vm_inf();
        vm_init();
        executeASM();
    } else {
        executeASM();
        leave_step_mode();
    }
}

void MainWindow::show_stack() {
    centralWidget()->findChild<QListWidget*>("stackList")->clear();
    for (int i = 1;i < top; ++i) {
        centralWidget()->findChild<QListWidget*>("stackList")->addItem(QString::number(i - 1) + ": " + QString::number(stack[i]));
    }
}

void MainWindow::step() {
    if (!code_cnt) {
        centralWidget()->findChild<QTextEdit*>("outputEdit")->setText(QString("NO VM ASM Code!"));
        return;
    }
    if (!step_mode) {
        centralWidget()->findChild<QTextEdit*>("outputEdit")->setText(QString(""));
        prep_vm_inf();
        vm_init();
        enter_step_mode();
    } else {
        char vm_out[20] = {0 * 20};
        vm_step(vm_inf, vm_out);
        if (vm_out[0]) {
            stream<<vm_out;
            std::memset(vm_out,0,sizeof(vm_out));
        }
        centralWidget()->findChild<QListWidget*>("asmList")->setCurrentRow(cur);
        show_stack();
        if (cur >= code_cnt) {
            buf.clear();
            leave_step_mode();
        }
    }
}

void MainWindow::handleActions(QAction *a) {
    QString const& cmd = a -> objectName();
    if (cmd == "actionLoad") {
        QString fileName = QFileDialog::getOpenFileName(this, tr("Open x0 File"),".",tr("x0 Program File(*x0)"));
        QFile file(fileName);
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QByteArray t = file.readAll();
            centralWidget()->findChild<QTextEdit*>("textEdit")->setText(QString(t));
        }
    } else if (cmd == "actionSaveX0") {
        QString fileName = QFileDialog::getSaveFileName(this,tr("Save x0 File"),".",tr("x0 Program File(*x0)"));
        if (fileName.length()) {
            QFile file(fileName + ".x0");
            file.open(QIODevice::WriteOnly | QIODevice::Text);
            QTextStream output(&file);
            output<<centralWidget()->findChild<QTextEdit*>("textEdit")->toPlainText();
        }
    } else if (cmd == "actionSetPath") {
        QString path = QFileDialog::getOpenFileName(this, tr("Set x0 Compiler Path"),".",tr("x0 Compiler(*)"));
        compilerPath = path;
    } else if (cmd == "actionCompile")
        compile();
    else if (cmd == "actionRun")
        runASM();
    else if (cmd == "actionSaveVM") {
        QString fileName = QFileDialog::getSaveFileName(this,tr("Save VM ASM Code"),".",tr("VM ASM File(*vmasm)"));
        if (fileName.length() && code_cnt) {
            std::FILE* f = std::fopen((fileName + ".vmasm").toStdString().c_str(),"w");
            vm_save_ins(f);
            std::fclose(f);
        }
    }
}
