import './bootstrap';

window.getToken = async function () {
    const token = localStorage.getItem('kado:token');
    if (token) {
        return token;
    }
    return await refreshToken();
}

window.refreshToken = function () {
    fetch('/token', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
        },
    }).then(response => {
        if (response.ok) {
            return response.json();
        }
        throw new Error('Failed to fetch token');
    }).then(data => {
        window.Kado.token = data.token;
        localStorage.setItem('kado:token', data.token);
        return data.token;
    }).catch(error => {
        console.error('Error fetching token:', error);
    });
}

window.resetToken = function () {
    localStorage.removeItem('kado:token');
    refreshToken();
}

    ; (async () => {
        window.Kado.token = await getToken();
    })();
