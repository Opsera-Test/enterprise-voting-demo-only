from flask import Flask, render_template, request, make_response, g, jsonify
from redis import Redis
import os
import socket
import random
import json
import logging

option_a = os.getenv('OPTION_A', "Cats")
option_b = os.getenv('OPTION_B', "Dogs")
hostname = socket.gethostname()

app = Flask(__name__)

gunicorn_error_logger = logging.getLogger('gunicorn.error')
app.logger.handlers.extend(gunicorn_error_logger.handlers)
app.logger.setLevel(logging.INFO)

# ═══════════════════════════════════════════════════════════════════════════════
# ERROR SIMULATION - Simple ON/OFF toggle for canary rollback testing
# ═══════════════════════════════════════════════════════════════════════════════

# Simple global state - errors OFF by default
ERROR_SIM_ENABLED = False

def get_redis():
    if not hasattr(g, 'redis'):
        redis_host = os.getenv('REDIS_HOST', 'redis')
        redis_port = int(os.getenv('REDIS_PORT', 6379))
        g.redis = Redis(host=redis_host, port=redis_port, db=0, socket_timeout=5)
    return g.redis

@app.route("/api/error-sim", methods=['GET'])
def get_error_sim_status():
    """Get current error simulation status"""
    global ERROR_SIM_ENABLED
    return jsonify({'enabled': ERROR_SIM_ENABLED})

@app.route("/api/error-sim", methods=['POST'])
def toggle_error_sim():
    """Toggle error simulation ON/OFF"""
    global ERROR_SIM_ENABLED
    ERROR_SIM_ENABLED = not ERROR_SIM_ENABLED
    status = "ENABLED" if ERROR_SIM_ENABLED else "DISABLED"
    app.logger.info('Error simulation %s', status)
    return jsonify({'enabled': ERROR_SIM_ENABLED})

@app.route("/health", methods=['GET'])
def health():
    """Health check - always returns 200"""
    return jsonify({'status': 'healthy', 'hostname': hostname})

@app.route("/", methods=['POST','GET'])
def hello():
    global ERROR_SIM_ENABLED

    voter_id = request.cookies.get('voter_id')
    if not voter_id:
        voter_id = hex(random.getrandbits(64))[2:-1]

    vote = None

    if request.method == 'POST':
        # If error simulation is ON, fail EVERY request with 500
        if ERROR_SIM_ENABLED:
            app.logger.error('SIMULATED ERROR: Error simulation is ON')
            return jsonify({
                'error': 'Simulated Error',
                'message': 'Error simulation is enabled for canary rollback testing'
            }), 500

        # Normal vote processing
        redis = get_redis()
        vote = request.form['vote']
        app.logger.info('Received vote for %s', vote)
        data = json.dumps({'voter_id': voter_id, 'vote': vote})
        redis.rpush('votes', data)

    resp = make_response(render_template(
        'index.html',
        option_a=option_a,
        option_b=option_b,
        hostname=hostname,
        vote=vote,
    ))
    resp.set_cookie('voter_id', voter_id)
    return resp


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80, debug=True, threaded=True)
