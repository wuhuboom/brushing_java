#!/bin/bash

# 配置文件
JAR_FILE="brushing-admin.jar"  # JAR 文件路径
PID_FILE="app.pid"
LOG_FILE="brushing.out"
JVM_OPTS="-Xms1024m -Xmx2048m"

# 启动函数
start() {
    if [ -f "$PID_FILE" ]; then
        if check_status; then
            echo "应用已在运行，PID: $(cat $PID_FILE)"
            return 1
        fi
    fi
    
    echo "正在启动 $JAR_FILE ..."
    (nohup java $JVM_OPTS -jar "$JAR_FILE" >> "$LOG_FILE" 2>&1) &
    echo $! > "$PID_FILE"
    
    # 等待几秒检查是否启动成功
    sleep 2
    if check_status; then
        echo "$JAR_FILE 启动成功，PID: $(cat $PID_FILE)"
    else
        echo "$JAR_FILE 启动失败，请检查日志: $LOG_FILE"
        rm -f "$PID_FILE"
        return 1
    fi
}

# 停止函数
stop() {
    if [ ! -f "$PID_FILE" ]; then
        echo "应用未运行"
        return 1
    fi
    
    PID=$(cat "$PID_FILE")
    echo "正在停止 $JAR_FILE (PID: $PID)..."
    
    kill "$PID"
    
    # 等待进程结束
    for i in {1..10}
    do
        if ! check_status; then
            echo "$JAR_FILE 已停止"
            rm -f "$PID_FILE"
            return 0
        fi
        sleep 1
    done
    
    echo "无法正常停止进程，尝试强制终止..."
    kill -9 "$PID" 2>/dev/null
    rm -f "$PID_FILE"
    echo "$JAR_FILE 已强制停止"
}

# 重启函数
restart() {
    if [ -f "$PID_FILE" ]; then
        stop
        sleep 2
    fi
    start
}

# 检查状态函数
check_status() {
    if [ ! -f "$PID_FILE" ]; then
        return 1
    fi
    
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null; then
        return 0
    else
        rm -f "$PID_FILE"
        return 1
    fi
}

# 如果传入参数，则直接执行对应命令
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        if check_status; then
            echo "$JAR_FILE 正在运行，PID: $(cat $PID_FILE)"
        else
            echo "$JAR_FILE 未运行"
        fi
        ;;
    *)
        echo "无效的操作: $1"
        echo "用法: 请输入 start, stop, restart 或 status"
        exit 1
        ;;
esac

exit 0
