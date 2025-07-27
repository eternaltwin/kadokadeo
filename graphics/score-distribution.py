import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import norm
import random

def generate_bell_curve_score(thresholds):
    """
    Génère un score basé sur des courbes en cloche pour chaque seuil

    Args:
        thresholds: Liste des seuils [32424, 44433, 50438]

    Returns:
        int: Score généré
    """
    # Définir les ranges pour chaque cloche
    ranges = []
    peaks = [0.7, 0.15, 0.05]  # Probabilités décroissantes pour chaque cloche

    # Range 1: 0 -> premier seuil
    ranges.append((0, thresholds[0]))

    # Range 2: premier seuil -> deuxième seuil
    ranges.append((thresholds[0], thresholds[1]))

    # Range 3: deuxième seuil -> troisième seuil + 5%
    max_range = thresholds[2] * 1.05
    ranges.append((thresholds[1], max_range))

    # Choisir quelle cloche utiliser selon les probabilités
    rand = random.random()
    cumulative_prob = 0
    selected_range = 0

    for i, peak in enumerate(peaks):
        cumulative_prob += peak
        if rand <= cumulative_prob:
            selected_range = i
            break

    # Générer un score dans la range sélectionnée avec une distribution normale
    range_min, range_max = ranges[selected_range]
    range_center = (range_min + range_max) / 2
    range_width = (range_max - range_min) / 6  # Écart-type = 1/6 de la largeur

    # Générer le score avec distribution normale
    score = np.random.normal(range_center, range_width)

    # S'assurer que le score reste dans la range
    score = max(range_min, min(range_max, score))

    return int(score)

def visualize_bell_curves(thresholds, num_samples=10000):
    """
    Visualise les courbes en cloche et génère des échantillons pour tester
    """
    # Définir les ranges
    ranges = []
    ranges.append((0, thresholds[0]))
    ranges.append((thresholds[0], thresholds[1]))
    ranges.append((thresholds[1], thresholds[2] * 1.05))

    peaks = [0.6, 0.3, 0.1]
    colors = ['blue', 'green', 'red']
    labels = ['Cloche 1 (Facile)', 'Cloche 2 (Moyen)', 'Cloche 3 (Difficile)']

    # Créer la figure
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 10))

    # Graphique 1: Courbes théoriques
    x_total = np.linspace(0, thresholds[2] * 1.1, 1000)
    y_total = np.zeros_like(x_total)

    for i, (range_min, range_max) in enumerate(ranges):
        # Centre et écart-type de chaque cloche
        center = (range_min + range_max) / 2
        std = (range_max - range_min) / 6

        # Créer la courbe normale pour cette range
        x_range = np.linspace(range_min, range_max, 200)
        y_range = peaks[i] * norm.pdf(x_range, center, std)

        # Normaliser pour que le pic soit exactement à la valeur souhaitée
        y_range = y_range * (peaks[i] / np.max(y_range))

        # Tracer cette cloche
        ax1.plot(x_range, y_range, color=colors[i], linewidth=2, label=f'{labels[i]} (pic: {peaks[i]})')
        ax1.fill_between(x_range, y_range, alpha=0.3, color=colors[i])

        # Ajouter à la courbe totale
        for j, x_val in enumerate(x_total):
            if range_min <= x_val <= range_max:
                # Calculer la probabilité pour ce point
                prob = peaks[i] * norm.pdf(x_val, center, std)
                prob = prob * (peaks[i] / norm.pdf(center, center, std))  # Normaliser
                y_total[j] += prob

    # Ajouter les lignes verticales pour les seuils
    for i, threshold in enumerate(thresholds):
        ax1.axvline(x=threshold, color='black', linestyle='--', alpha=0.7,
                   label=f'Seuil {i+1}: {threshold}')

    ax1.set_xlabel('Score')
    ax1.set_ylabel('Probabilité')
    ax1.set_title('Courbes en cloche théoriques pour la génération de scores')
    ax1.legend()
    ax1.grid(True, alpha=0.3)

    # Graphique 2: Distribution réelle avec échantillons
    samples = [generate_bell_curve_score(thresholds) for _ in range(num_samples)]

    ax2.hist(samples, bins=50, density=True, alpha=0.7, color='purple',
             label=f'Échantillons générés (n={num_samples})')

    # Ajouter les seuils
    for i, threshold in enumerate(thresholds):
        ax2.axvline(x=threshold, color='black', linestyle='--', alpha=0.7,
                   label=f'Seuil {i+1}: {threshold}')

    ax2.set_xlabel('Score')
    ax2.set_ylabel('Densité de probabilité')
    ax2.set_title('Distribution réelle des scores générés')
    ax2.legend()
    ax2.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.show()

    # Statistiques
    print(f"Statistiques sur {num_samples} échantillons:")
    print(f"Score moyen: {np.mean(samples):.0f}")
    print(f"Score médian: {np.median(samples):.0f}")
    print(f"Score min: {min(samples)}")
    print(f"Score max: {max(samples)}")

    # Répartition par range
    range1_count = sum(1 for s in samples if 0 <= s <= thresholds[0])
    range2_count = sum(1 for s in samples if thresholds[0] < s <= thresholds[1])
    range3_count = sum(1 for s in samples if thresholds[1] < s <= thresholds[2] * 1.05)

    print(f"\nRépartition par range:")
    print(f"Range 1 (0 - {thresholds[0]}): {range1_count/num_samples*100:.1f}%")
    print(f"Range 2 ({thresholds[0]} - {thresholds[1]}): {range2_count/num_samples*100:.1f}%")
    print(f"Range 3 ({thresholds[1]} - {int(thresholds[2]*1.05)}): {range3_count/num_samples*100:.1f}%")

# Exemple d'utilisation
thresholds = [32424, 44433, 50438]
visualize_bell_curves(thresholds)

# Test de génération de quelques scores
print("\nExemples de scores générés:")
for i in range(10):
    score = generate_bell_curve_score(thresholds)
    print(f"Score {i+1}: {score}")
