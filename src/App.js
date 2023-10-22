import React, { useState } from 'react';
import './App.css';

const API_URL = '/poll';

function App() {
    const [score, setScore] = useState(null);
    const [feedback, setFeedback] = useState('');
    const [apiResponse, setApiResponse] = useState(null);
    const [submitted, setSubmitted] = useState(false);
    const email = new URLSearchParams(window.location.search).get('email');

    const handleSubmit = async () => {
        setSubmitted(true);
        try {
            const response = await fetch(`${API_URL}?email=${email}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ score, feedback })
            });

            const data = await response.json();

            if (data && data.message) {
                setApiResponse(data.message);
            } else {
                console.error("Unexpected data format:", data);
                alert('Error: Unexpected response from server.');
            }
        } catch (error) {
            console.error("There was a problem with the fetch operation:", error);
            alert('Error: Could not submit the response. Please try again later.');
        }
    }

    if (submitted) {
        return (
            <div className="App">
                <p>{apiResponse}</p>
            </div>
        );
    }

    return (
        <div className="App">
            <h2>Poll</h2>
            <p>Your email: <strong>{email}</strong></p>
            <p>This poll is completely anonymous.</p>

            <h4>How likely are you to recommend Blue Sentry Cloud to a friend?</h4>
            {[...Array(10)].map((_, i) => (
                <label key={i}>
                    <input
                        type="radio"
                        value={i + 1}
                        checked={score === i + 1}
                        onChange={() => setScore(i + 1)}
                    />
                    {i + 1}
                </label>
            ))}

            <h4>Why did you answer that number?</h4>
            <textarea
                value={feedback}
                onChange={e => setFeedback(e.target.value)}
                rows="4"
                cols="50"
            ></textarea>

            <button onClick={handleSubmit} disabled={submitted}>Submit</button>
        </div>
    );
}

export default App;
