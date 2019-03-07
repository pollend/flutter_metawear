
import 'dart:async';

/**
 * Created by eric on 12/8/17.
 */
class TimedTask<T> {
    final Future<T> taskSource;
    CancellationTokenSource cts;

    TimedTask() { }

     Future<T> execute(String msgFormat, int timeout, Runnable action) {
        if (taskSource != null && !taskSource.getTask().isCompleted()) {
            return taskSource.getTask();
        }

        cts = new CancellationTokenSource();
        taskSource = new TaskCompletionSource<>();
        action.run();

        if (timeout != 0) {
            final ArrayList<Task<?>> tasks = new ArrayList<>();
            tasks.add(taskSource.getTask());
            tasks.add(Task.delay(timeout, cts.getToken()));

            Task.whenAny(tasks).continueWith(task -> {
                if (task.getResult() != tasks.get(0)) {
                    setError(new TimeoutException(String.format(msgFormat, timeout)));
                } else {
                    cts.cancel();
                }
                return null;
            });
        }
        return taskSource.getTask();
    }

    bool isCompleted() {
        return taskSource != null && taskSource.getTask().isCompleted();
    }

    void cancel() {
        taskSource.trySetCancelled();
    }

    void setResult(T result) {
        taskSource.trySetResult(result);
    }

    void setError(Exception error) {
        taskSource.trySetError(error);
    }
}