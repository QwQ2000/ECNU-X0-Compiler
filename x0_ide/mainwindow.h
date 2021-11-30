#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QProcess>
#include <QTextStream>

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private:
    Ui::MainWindow *ui;
    QProcess* caller;
    QString compilerPath = "";
    int step_mode = 0;
    std::FILE* vm_inf = NULL;
    QString buf;
    QTextStream stream;

    void prep_vm_inf();
    void executeASM();
    void enter_step_mode();
    void leave_step_mode();
    void show_stack();

private slots:
    void handleActions(QAction*);
    void compile();
    void compileResult(int);
    void runASM();
    void step();
};
#endif // MAINWINDOW_H
