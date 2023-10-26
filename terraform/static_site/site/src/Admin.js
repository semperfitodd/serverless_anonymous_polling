import React, { useState, useEffect } from 'react';
import { Bar, Pie } from 'react-chartjs-2';
import { Chart } from 'chart.js';
import ChartDataLabels from 'chartjs-plugin-datalabels';
import { BarController, BarElement, CategoryScale, LinearScale, DoughnutController, ArcElement } from 'chart.js';

Chart.register(ChartDataLabels);
Chart.register(BarController, BarElement, CategoryScale, LinearScale, DoughnutController, ArcElement);

const SEND_API_URL = '/send';
const RESULTS_API_URL = '/results';

function Admin() {
    const [results, setResults] = useState(null);
    const [lambdaResponse, setLambdaResponse] = useState(null);

    useEffect(() => {
        async function fetchResults() {
            try {
                const response = await fetch(RESULTS_API_URL);
                const data = await response.json();
                setResults(data);
            } catch (error) {
                console.error("There was a problem fetching the results:", error);
            }
        }

        fetchResults();
        const interval = setInterval(fetchResults, 60000);  // Fetch every 60 seconds

        return () => clearInterval(interval);  // Clear interval on component unmount
    }, []);

    const handleSendRequest = async () => {
        const userConfirmed = window.confirm("Submitting this request will erase all previous data. Do you want to proceed?");

        if (!userConfirmed) {
            return; // Exit the function if the user clicked "Cancel"
        }

        try {
            const response = await fetch(SEND_API_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                }
            });

            const data = await response.json();
            if (data && data.message) {
                setLambdaResponse(data.message);
            } else {
                console.error("Unexpected data format:", data);
                alert('Error: Unexpected response from server.');
            }
        } catch (error) {
            console.error("There was a problem with the fetch operation:", error);
            alert('Error: Could not send the request. Please try again later.');
        }
    };

    if (!results) return <div>Loading...</div>;

    const pieData = {
    labels: ['Completed', 'Not Completed'],
    datasets: [{
        data: [results.completion_percentage, 100 - results.completion_percentage],
        backgroundColor: ['blue', 'red']
    }]
    };

    const pieOptions = {
        plugins: {
            legend: { display: false },
            tooltip: { enabled: false },
            datalabels: {
                display: true,
                color: 'white',
                formatter: (value) => `${value}%`
            }
        }
    };

    const barData = {
        labels: Object.keys(results.score_counts),
        datasets: [{
            data: Object.values(results.score_counts),
            backgroundColor: Object.keys(results.score_counts).map((key) =>
                parseInt(key) <= 6 ? 'red' : 'blue'
            )
        }]
    };

    const barOptions = {
        scales: {
            x: {
                type: 'category',
                display: true,
                title: {
                    display: true,
                    text: 'Score'
                }
            },
            y: {
                beginAtZero: true,
                display: true,
                title: {
                    display: true,
                    text: 'Count'
                }
            }
        },
        plugins: {
            legend: { display: false },
            datalabels: {
                display: true,
                align: 'end',
                color: 'white',
                anchor: 'end'
            }
        }
    };
    return (
        <div className="App">
            <h2>Admin Page</h2>
            {lambdaResponse && <p>{lambdaResponse}</p>}
            <div className="chart-container">
                <Pie data={pieData} options={pieOptions} />
                <Bar data={barData} options={barOptions} />
            </div>
            <div className="respondent-table">
                <div className="table-header">
                    <div>Responded</div>
                    <div>Not Responded</div>
                </div>
                <div className="table-body">
                    <div>{results.respondents_responded.map(email => <div key={email}>{email}</div>)}</div>
                    <div>{results.respondents_not_responded.map(email => <div key={email}>{email}</div>)}</div>
                </div>
            </div>
            <button onClick={handleSendRequest}>Send Emails</button>
        </div>
    );
}

export default Admin;
