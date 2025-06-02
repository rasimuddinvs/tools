#!/bin/bash
source ~/rasim_bashrc
source ~/function
# Pomodoro Timer with SIGINT Pause Control
# Usage: ./pomodoro_day.sh

# Configuration
WORK_MINUTES=25
SHORT_BREAK=5
LONG_BREAK=15
TOTAL_SESSIONS=13
BELL=$'\a'  # Terminal bell

# State variables
current_session=0
paused=false
interrupted=false

# Cleanup function
cleanup() {
    echo -e "\n\nTotal completed sessions: $((current_session))/$TOTAL_SESSIONS"
    echo "Pomodoro day ended!"
    exit 0
}

# Pause/Resume function
toggle_pause() {
    if $paused; then
        paused=false
        echo -e "\nRESUMING session $current_session..."
    else
        paused=true
        echo -e "\nPAUSED (Session $current_session)"
        echo "Press Ctrl+C again to resume..."
    fi
}

# Single Ctrl+C handler
handle_interrupt() {
    if $paused; then
        # Second Ctrl+C - resume
        toggle_pause
    else
        # First Ctrl+C - pause
        toggle_pause
    fi
}

# Set trap
trap handle_interrupt SIGINT

# Countdown function
countdown() {
    local minutes=$1
    local label="$2"
    local seconds=0
    local remaining=$((minutes * 60))
    
    echo -e "\n$label ($minutes minutes)"
    
    while (( remaining > 0 )) && ! $interrupted; do
        if ! $paused; then
            printf "\r%02d:%02d remaining " $((remaining/60)) $((remaining%60))
            ((remaining--))
            sleep 1
        else
            sleep 0.1
        fi
    done
    
    printf "\r%02d:%02d completed \n" $((minutes)) 0
    echo -n "$BELL"  # Play terminal bell
}

# Main Pomodoro loop
echo "Starting Pomodoro Day with $TOTAL_SESSIONS sessions"
echo "Press Ctrl+C to pause/resume"

for (( session=1; session<=TOTAL_SESSIONS; session++ )); do
    current_session=$session
    
    # Work session
    speak "Start Working."
    countdown $WORK_MINUTES "SESSION $session/$TOTAL_SESSIONS - WORK TIME"
    notif "work is over" "time to take a break"
    speak "Work Ends. Take a break."
    $interrupted && break
    
    # Break logic
    if (( session < TOTAL_SESSIONS )); then
        if (( session % 4 == 0 )); then
            speak "Work Ends. Take a Long break"
            countdown $LONG_BREAK "LONG BREAK TIME"
            notif "break is over" "time to start working"
        else
            speak "Take a short break"
            countdown $SHORT_BREAK "SHORT BREAK TIME"
            speak "short break is over"
        fi
        $interrupted && break
    fi
done

cleanup
