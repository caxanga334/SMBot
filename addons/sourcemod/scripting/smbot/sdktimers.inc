/**
 * Timers ported from the Source SDK
 * https://github.com/alliedmodders/hl2sdk/blob/c33f7155e9aff9573c20d86e10c8158425a3d67a/game/shared/util_shared.h#L484
 */

#if defined _sdktimers_included
 #endinput
#endif
#define _sdktimers_included

enum struct IntervalTimer
{
    float timestamp;

    void Reset()
    {
        this.timestamp = GetGameTime();
    }

    void Start()
    {
        this.timestamp = GetGameTime();
    }

    void Invalidate()
    {
        this.timestamp = -1.0;
    }

    bool HasStarted()
    {
        return this.timestamp > 0.0;
    }

    float GetElapsedTime()
    {
        return this.HasStarted() ? GetGameTime() - this.timestamp : 999999.9;
    }

	bool IsLessThen(float duration)
	{
		return (GetGameTime() - this.timestamp < duration) ? true : false;
	}

	bool IsGreaterThen(float duration)
	{
		return (GetGameTime() - this.timestamp > duration) ? true : false;
	}
}

enum struct CountdownTimer
{
    float timestamp;
    float duration;

	void Reset()
	{
		this.timestamp = GetGameTime() + this.duration;
	}		

	void Start(float duration)
	{
		this.timestamp = GetGameTime() + duration;
		this.duration = duration;
	}

	void Invalidate()
	{
		this.timestamp = -1.0;
	}		

	bool HasStarted()
	{
		return (this.timestamp > 0.0);
	}

	bool IsElapsed()
	{
		return (GetGameTime() > this.timestamp);
	}

	float GetElapsedTime()
	{
		return GetGameTime() - this.timestamp + this.duration;
	}

	float GetRemainingTime()
	{
		return (this.timestamp - GetGameTime());
	}

	float GetCountdownDuration()
	{
		return (this.timestamp > 0.0) ? this.duration : 0.0;
	}
}