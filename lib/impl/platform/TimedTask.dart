
import 'dart:async';

import 'package:flutter_blue/flutter_blue.dart';

/**
 * Created by eric on 12/8/17.
 */
class TimedTask<T> {
    final Stream<T> taskSource;
    StreamSubscription<T> subscription;

    TimedTask(this.taskSource);

     Future<T> execute(String msgFormat, int timeout, void execute(T e)) async {
       bool flag = false;
       StreamSubscription<T> sub = taskSource.listen((T e) => {
          execute(e),
          subscription.cancel()
       });

       this.subscription = sub;
       Future.delayed(Duration(seconds: 1),() => flag = true);
       await sub.asFuture();
       if(flag == true) {
         throw TimeoutException(msgFormat, Duration(seconds: timeout));
       }
//
//
//
//
//       if (taskSource != null && !taskSource.getTask().isCompleted()) {
//       return taskSource.getTask();
//       }
//
//       cts = new CancellationTokenSource();
//       taskSource = new
//       } TaskCompletionSource<>();
//        action.run();
//
//        if (timeout != 0) {
//            final ArrayList<Task<?>> tasks = new ArrayList<>();
//            tasks.add(taskSource.getTask());
//            tasks.add(Task.delay(timeout, cts.getToken()));
//
//            Task.whenAny(tasks).continueWith(task -> {
//                if (task.getResult() != tasks.get(0)) {
//                    setError(new TimeoutException(String.format(msgFormat, timeout)));
//                } else {
//                    cts.cancel();
//                }
//                return null;
//            });
//        }
//        return taskSource.getTask();
    }

    bool isCompleted() {
        return taskSource != null && taskSource.getTask().isCompleted();
    }

    void cancel() async{
       await subscription.cancel();
    }

    void setResult(Future<T> result) {
        taskSource.trySetResult(result);
    }

    void setError(Exception error) {
        taskSource.trySetError(error);
    }
}