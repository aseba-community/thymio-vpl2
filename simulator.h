#ifndef SIMULATOR_H
#define SIMULATOR_H

#include <QVariantMap>

class Simulator: public QObject {
	Q_OBJECT

public slots:
	QString setProgram(QVariantMap events, QString source);
};

#endif // SIMULATOR_H
