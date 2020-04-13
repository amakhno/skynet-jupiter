FROM continuumio/miniconda3:4.5.4

#Install required packages
RUN echo "deb http://deb.debian.org/debian buster main" >> /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y build-essential gfortran cmake libhdf5-dev swig3.0 \ 
  libgsl-dev libboost-dev liblapack-dev libblas-dev \
  libcairomm-1.0-dev libsigc++-2.0-dev ffmpeg libboost-system-dev \
  libboost-filesystem-dev libboost-serialization-dev sudo

#Add user 'noir'
RUN adduser --disabled-password --gecos '' noir
RUN adduser noir sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER noir

#Clone skynet
WORKDIR /home/noir
RUN git config --global core.autocrlf false
RUN git clone https://bitbucket.org/jlippuner/skynet.git skynet-repo

#Add pardiso binaries
ADD /pardiso/ /home/noir/pardiso

#Install jupyter
RUN sudo /opt/conda/bin/conda install jupyter -y --quiet

#Install skynet
RUN mkdir /home/noir/skynet-build
WORKDIR /home/noir/skynet-build
RUN cmake -DSKYNET_MATRIX_SOLVER=pardiso      \
  -DCMAKE_INSTALL_PREFIX=/home/noir/skynet-lib /home/noir/skynet-repo \
  -DCMAKE_PREFIX_PATH=/home/noir/pardiso/ \
  -DPYTHON_LIBRARY=/opt/conda/lib/libpython3.7m.so \
  -DPYTHON_INCLUDE_DIR=/opt/conda/include/python3.7m/ \
  -DPYTHON_EXECUTABLE=/opt/conda/bin/python
RUN make -j4 install

ENV PARDISO_LIC_PATH=/home/noir/pardiso-lic/

######## Test ENTRYPOINT ########
#ENTRYPOINT cd /home/noir/skynet-build && \
#            make test

#Add paths
RUN echo "export PYTHONPATH=/home/noir/skynet-lib/lib:\$PYTHONPATH" >> ~/.bashrc
RUN echo "export PATH=/opt/conda/bin:\$PATH" >> ~/.bashrc
RUN echo "export JUPYTER_PATH=/home/noir/skynet-lib/lib:\$JUPYTER_PATH" >> ~/.bashrc

#Remove build directories
RUN rm -r /home/noir/skynet-build
RUN rm -r /home/noir/skynet-repo

#Volume with license
VOLUME "/home/noir/pardiso-lic" 
#Volume with jupyter configuration
VOLUME "/home/noir/.jupyter"
#Current working dir
VOLUME "/home/noir/notebook"
EXPOSE 8888

#Update requirements and run jupiter
ENTRYPOINT sudo /opt/conda/bin/pip install -r /home/noir/notebook/requirements.txt \
            && /opt/conda/bin/jupyter notebook \
            --notebook-dir=/home/noir/notebook \
            --ip='0.0.0.0' \
            --port=8888 \
            --no-browser \
             > /home/noir/notebook/log.file 2>&1

#Sample run 
#docker run -v D:\vscode-remote-try-python\pardiso-lic:/home/noir/pardiso-lic/ 
#           -v D:\Test:/home/noir/notebook 
#           -v D:\vscode-remote-try-python\configuration:/home/noir/.jupyter 
#           -p 8888:8888 
#           skynet
