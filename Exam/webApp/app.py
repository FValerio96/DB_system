# app.py - StageUp Audiovisual Equipment Booking System
from flask import Flask, render_template, request, redirect, url_for, flash
import oracledb
import datetime

app = Flask(__name__)
app.secret_key = 'supersecretkey'

# Oracle DB connection parameters
DB_USER     = 'System'
DB_PASSWORD = 'password123'
DB_SID      = 'localhost:1521/xe'


def get_db_connection():
    try:
        return oracledb.connect(user=DB_USER, password=DB_PASSWORD, dsn=DB_SID)
    except Exception as e:
        print("DB connection error:", e)
        return None


# Homepage
@app.route('/')
def index():
    return render_template('index.html')


# Operation 1: Register a new customer
@app.route('/register_customer', methods=['GET', 'POST'])
def register_customer():
    if request.method == 'POST':
        conn = get_db_connection()
        if conn is None:
            flash("Database connection error", "danger")
            return redirect(url_for('register_customer'))
        try:
            cur = conn.cursor()
            cur.callproc("proc_register_customer", [
                request.form['cust_id'],
                request.form['name'],
                request.form['cust_type'],
                request.form['email'],
                request.form['phone'],
                request.form['address']
            ])
            conn.commit()
            flash("Customer registered successfully", "success")
        except oracledb.DatabaseError as e:
            flash(f"Error registering customer: {e}", "danger")
        finally:
            cur.close()
            conn.close()
        return redirect(url_for('index'))
    return render_template('register_customer.html')


# Operation 2: Record a new booking
@app.route('/add_booking', methods=['GET', 'POST'])
def add_booking():
    if request.method == 'POST':
        try:
            booking_date = datetime.datetime.strptime(
                request.form['booking_date'], '%Y-%m-%d').date()
        except Exception:
            flash("Invalid date format", "danger")
            return redirect(url_for('add_booking'))

        conn = get_db_connection()
        if conn is None:
            flash("Database connection error", "danger")
            return redirect(url_for('add_booking'))
        try:
            cur = conn.cursor()
            cur.callproc("proc_add_booking", [
                request.form['booking_id'],
                request.form['btype'],
                booking_date,
                int(request.form['duration']),
                float(request.form['cost']),
                request.form['method'],
                request.form['contract_type'],
                request.form['team_code'],
                request.form['customer_id'],
                request.form['location_id']
            ])
            conn.commit()
            flash("Booking recorded successfully", "success")
        except Exception as e:
            flash(f"Error recording booking: {e}", "danger")
        finally:
            cur.close()
            conn.close()
        return redirect(url_for('index'))
    return render_template('add_booking.html')


# Operation 3: Register a new event location
@app.route('/register_location', methods=['GET', 'POST'])
def register_location():
    if request.method == 'POST':
        conn = get_db_connection()
        if conn is None:
            flash("Database connection error", "danger")
            return redirect(url_for('register_location'))
        try:
            cur = conn.cursor()
            cur.callproc("proc_register_location", [
                request.form['location_id'],
                request.form['street'],
                request.form['house_number'],
                request.form['postal_code'],
                request.form['city'],
                request.form['province'],
                int(request.form['setup_time']),
                int(request.form['equip_capacity']),
                request.form['customer_id']
            ])
            conn.commit()
            flash("Event location registered successfully", "success")
        except Exception as e:
            flash(f"Error registering location: {e}", "danger")
        finally:
            cur.close()
            conn.close()
        return redirect(url_for('index'))
    return render_template('register_location.html')


# Operation 4: View teams that handled setups at a specific event location
@app.route('/teams_at_location', methods=['GET', 'POST'])
def teams_at_location():
    teams       = []
    location_id = None

    if request.method == 'POST':
        location_id = request.form.get('location_id')
        conn = get_db_connection()
        if conn is None:
            flash("Database connection error", "danger")
            return redirect(url_for('teams_at_location'))
        try:
            cur = conn.cursor()
            out_cursor = cur.var(oracledb.CURSOR)
            cur.callproc("proc_get_teams_at_location", [location_id, out_cursor])
            teams = out_cursor.getvalue().fetchall()
            if not teams:
                flash(f"No teams found for location '{location_id}'", "warning")
        except Exception as e:
            flash(f"Error retrieving teams: {e}", "danger")
        finally:
            cur.close()
            conn.close()

    return render_template('teams_at_location.html',
                           teams=teams, location_id=location_id)


# Operation 5: Event locations ranked by number of bookings (descending)
@app.route('/ranked_locations')
def ranked_locations():
    locations = []
    conn = get_db_connection()
    if conn is None:
        flash("Database connection error", "danger")
        return redirect(url_for('index'))
    try:
        cur = conn.cursor()
        out_cursor = cur.var(oracledb.CURSOR)
        cur.callproc("proc_get_locations_ranked", [out_cursor])
        locations = out_cursor.getvalue().fetchall()
    except Exception as e:
        flash(f"Error retrieving ranked locations: {e}", "danger")
    finally:
        cur.close()
        conn.close()
    return render_template('ranked_locations.html', locations=locations)


if __name__ == '__main__':
    app.run(debug=True)
