import numpy as np
import matplotlib.pyplot as plt
import random

def approach4_progressive_unlock(target_score, max_score=53000):
    """
    Approche 4: Déblocage progressif des niveaux de récompense
    """
    r = target_score / max_score

    # Définir les "niveaux" débloqués selon r
    base_points = [1, 10, 25, 50, 100, 500, 1000, 10000]
    base_proba = [0, 0.5, 0.75, 0.88, 0.94, 0.97, 0.99, 1]

    # Déblocage progressif
    if r < 0.2:
        unlock_level = 3  # Jusqu'à 50 points
    elif r < 0.4:
        unlock_level = 4  # Jusqu'à 100 points
    elif r < 0.6:
        unlock_level = 5  # Jusqu'à 500 points
    elif r < 0.8:
        unlock_level = 6  # Jusqu'à 1000 points
    else:
        unlock_level = 7  # Jusqu'à 10000 points

    # Prendre seulement les niveaux débloqués
    points_values = base_points[:unlock_level + 1]
    proba_points = base_proba[:unlock_level + 1]

    # Ajuster la dernière probabilité à 1
    proba_points[-1] = 1.0

    # Bonus: plus le score est bon, plus on pousse vers les hautes récompenses
    rand = random.random()

    # Modificateur basé sur r pour favoriser les hautes récompenses
    #if r > 0.7:
    #    # Pour les très bons scores, on pousse vers le haut
    #    rand = rand + (r - 0.7) * 0.125
    #    rand = min(rand, 1.0)
    if r < 0.5:
        # Pour les mauvais scores, on tire vers le bas
        rand = rand * (0.3 + r / 2)

    # Interpolation
    for i in range(len(proba_points) - 1):
        if proba_points[i] <= rand <= proba_points[i + 1]:
            ratio = (rand - proba_points[i]) / (proba_points[i + 1] - proba_points[i])
            points = points_values[i] + ratio * (points_values[i + 1] - points_values[i])
            return int(round(points))

    return points_values[-1]

def visualize_all_approaches():
    """
    Compare toutes les approches
    """
    max_score = 53000
    target_scores = np.arange(0, 50001, 2500)

    # Calculer les statistiques pour chaque targetScore
    means = []
    maxs = []
    mins = []

    for target_score in target_scores:
        samples = [approach4_progressive_unlock(target_score, max_score) for _ in range(100)]
        means.append(np.mean(samples))
        maxs.append(max(samples))
        mins.append(min(samples))

    r_values = target_scores / max_score
    fig, axes = plt.subplots(1, 1, figsize=(10, 6))

    ax = axes
    # Graphique principal
    ax.plot(r_values, means, color='blue', linewidth=3, label='Moyenne')
    ax.fill_between(r_values, mins, maxs, alpha=0.3, color='blue', label='Range Min-Max')

    ax.set_xlabel('r = targetScore / maxScore')
    ax.set_ylabel('Points de récompense')
    ax.set_title('Déblocage progressif')
    ax.legend()
    ax.grid(True, alpha=0.3)
    ax.set_yscale('log')

    plt.tight_layout()
    plt.show()

# Lancer toutes les visualisations
print("Génération des visualisations...")
visualize_all_approaches()
