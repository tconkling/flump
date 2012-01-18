//
// Flump - Copyright 2012 Three Rings Design

package flump {

import executor.Future;

import com.threerings.util.Log;
import com.threerings.util.Map;
import com.threerings.util.Maps;
import com.threerings.util.maps.ValueComputingMap;

public class Overseer
{
    public function monitor (future :Future, group :String="") :void {
        _monitored.put(future, group);
        future.completed.add(onCompletion);
    }

    public function insulate (f :Function, group :String="") :Function {
        return function (... args) :void {
            try {
                f.apply(this, args);
            } catch (e :Error) {
                failures.get(group).push(e);
            }
        }
    }

    public function get failures () :Map { return _failures; }
    public function get successes () :Map { return _successes; }

    protected function onCompletion (future :Future) :void {
        var group :* = _monitored.remove(future);
        if (future.isSuccessful) {
            if (group === undefined) log.warning("Unknown future succeeded", "future", future);
            else _successes.put(group, _successes.get(group) + 1)
        } else {
            if (group === undefined) log.warning("Unknown future failed", "future", future);
            else _failures.get(group).push(future.result);
        }
    }

    protected const _monitored :Map = Maps.newMapOf(Future);

    protected const _successes :Map = Maps.newBuilder(String).setDefaultValue(0).build();
    protected const _failures :Map = ValueComputingMap.newArrayMapOf(String);

    private static const log :Log = Log.getLog(Overseer);
}
}
